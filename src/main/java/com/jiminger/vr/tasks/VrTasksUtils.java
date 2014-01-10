package com.jiminger.vr.tasks;

import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import com.google.api.client.auth.oauth2.Credential;
import com.google.api.client.extensions.java6.auth.oauth2.AuthorizationCodeInstalledApp;
import com.google.api.client.extensions.jetty.auth.oauth2.LocalServerReceiver;
import com.google.api.client.googleapis.auth.oauth2.GoogleAuthorizationCodeFlow;
import com.google.api.client.googleapis.auth.oauth2.GoogleClientSecrets;
import com.google.api.client.googleapis.javanet.GoogleNetHttpTransport;
import com.google.api.client.http.HttpTransport;
import com.google.api.client.json.JsonFactory;
import com.google.api.client.json.jackson2.JacksonFactory;
import com.google.api.client.util.store.DataStoreFactory;
import com.google.api.client.util.store.FileDataStoreFactory;
import com.google.api.services.tasks.Tasks;
import com.google.api.services.tasks.TasksScopes;

public class VrTasksUtils
{
   /**
    * Be sure to specify the name of your application. If the application name is {@code null} or
    * blank, the application will log a warning. Suggested format is "MyCompany-ProductName/1.0".
    */
   private static final String APPLICATION_NAME = "VR-Tasks";

   /** Directory to store user credentials. */
   private static final java.io.File DATA_STORE_DIR =
       new java.io.File(System.getProperty("user.home"), ".store/vr_task");

   /**
    * Global instance of the {@link DataStoreFactory}. The best practice is to make it a single
    * globally shared instance across your application.
    */
   private static FileDataStoreFactory dataStoreFactory;

   /** Global instance of the HTTP transport. */
   private static HttpTransport httpTransport;

   /** Global instance of the JSON factory. */
   private static final JsonFactory JSON_FACTORY = JacksonFactory.getDefaultInstance();

   private static Tasks tasks;
   
   private static boolean initialized = false;

   /** Authorizes the installed application to access user's protected data. */
   private synchronized static Credential authorize() throws Exception 
   {
      if (!initialized)
      {
         httpTransport = GoogleNetHttpTransport.newTrustedTransport();
         dataStoreFactory = new FileDataStoreFactory(DATA_STORE_DIR);
         initialized = true;
      }
      
     // load client secrets
     GoogleClientSecrets clientSecrets = GoogleClientSecrets.load(JSON_FACTORY,
         new InputStreamReader(VrTasksUtils.class.getResourceAsStream("/client_secrets.json")));

     // set up authorization code flow
     GoogleAuthorizationCodeFlow flow = new GoogleAuthorizationCodeFlow.Builder(
         httpTransport, JSON_FACTORY, clientSecrets,
         Collections.singleton(TasksScopes.TASKS)).setDataStoreFactory(
         dataStoreFactory).build();
     // authorize
     return new AuthorizationCodeInstalledApp(flow, new LocalServerReceiver()).authorize("user");
   }
   
   public static void insertTasks(List<Task> tl) throws Exception
   {
      // authorization
      Credential credential = authorize();
      
      tasks = new Tasks.Builder(httpTransport, JSON_FACTORY, credential).setApplicationName(
            APPLICATION_NAME).build();
      
      for (Task task : tl)
      {
         Tasks.TasksOperations.Insert req = tasks.tasks().insert("@default",task.asTask());
         req.execute();
      }
   }
   
   public static List<Task> getTasks() throws Exception
   {
      httpTransport = GoogleNetHttpTransport.newTrustedTransport();
      dataStoreFactory = new FileDataStoreFactory(DATA_STORE_DIR);
      // authorization
      Credential credential = authorize();
      
      tasks = new Tasks.Builder(httpTransport, JSON_FACTORY, credential).setApplicationName(
            APPLICATION_NAME).build();
      
      Tasks.TasksOperations.List req = tasks.tasks().list("@default");
      req.setMaxResults(99999999L);
      com.google.api.services.tasks.model.Tasks tlist = req.execute();
      System.out.println(tlist);
      
      List<Task> ret = new ArrayList<Task>();
      
      int currentPageNumber = 0;
      while (tlist.getItems() != null && !tlist.getItems().isEmpty() && ++currentPageNumber <= 5) {
        for (com.google.api.services.tasks.model.Task task : tlist.getItems())
          ret.add(new Task(task));

        // Fetch the next page
        String nextPageToken = tlist.getNextPageToken();
        if (nextPageToken == null) {
          break;
        }
        req.setPageToken(nextPageToken);
        tlist = req.execute();
      }
      
      return ret;
   }
}
