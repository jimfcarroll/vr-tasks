package com.jiminger.vr.tasks;

import java.text.SimpleDateFormat;
import java.util.Date;

import com.google.api.client.util.DateTime;

public class Task
{
   private String title;
   private String notes;
   private long due;

   public Task(String title, long due, String notes)
   {
      this.title = title;
      this.due = due;
      this.notes = notes;
   }
   
   Task(com.google.api.services.tasks.model.Task task)
   {
      this.title = task.getTitle();
      this.notes = task.getNotes();
      DateTime dt = task.getDue();
      due = (dt == null) ? -1L : dt.getValue();
   }
   
   public String getTitle() { return title; }
   public String getNotes() { return notes; }
   public long getDue() { return due; }
   
   public String toString() { return "{ title:" + title + ", due:" + getDueAsString() + ", note:" + getNotes(); }
   
   public String getDueAsString()
   {
      SimpleDateFormat sdf = new SimpleDateFormat("MM/dd/yyyy");
      return sdf.format(new Date(due));
   }
   
   com.google.api.services.tasks.model.Task asTask()
   {
      com.google.api.services.tasks.model.Task ret = new com.google.api.services.tasks.model.Task();
      ret.setTitle(title);
      ret.setNotes(notes);
      ret.setDue(new DateTime(due));
      return ret;
   }
}
