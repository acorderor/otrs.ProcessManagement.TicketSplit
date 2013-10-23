otrs.ProcessManagement.TicketSplit
==================================

Modules to Extend OTRS Process Management. Create multiple tickets or subprocess from within a Process. 

Overview.

Since OTRS 3.2 there was a new module to create and run process from within OTRS. It included various modules to create transition actions while running the process, but there was none to be able to assign a task to multiple users or queues. 

Therefore we have developed 3 modules to be able to transition a process into multiple activities or subprocess that allow a process to be splitted into one or more tasks and assigned to different users or queues. 

Implementation.

SplitTicket

Allows the creation of one subprocess starting on a certain task of the process, it allows the user to copy some of the fields or all them into the new process, and allows the new process to be started in any task, doesn’t require an initial activity. 
It will copy the last article created in the main process ticket, usually the one created into the activity that gives birth to it and will always link the original ticket and the new one with the parent relation. 
The module is called SplitTicket.pm and can be placed into Custom otrs directory for better compatibility. 
It requires the following fields.

Queue: The queue where the new ticket will be created.
activity: The ActivityID for the first activity to be executed by the new process (subprocess)
fields: A comma separated list of Dynamic Fields that should be copied from the parent ticket into the new ticket. It replaces the information that should be entered into the first Activity Dialog.
process: The ProcessID to define the Process Type of the new ticket. 
title: The title for the subprocess

SplitTicketMulti.

Allows the creation of multiple subprocess from within one single process, it uses SplitTicket.pm and assigns the new subprocesses into different queues so the activities can be done by different agents. It allows the parallelization of the process and to assign different fields from the original ticket into the new ones.  It will link all the new subprocesses (tickets) as childs of the current process, and will also include the last article of the main process into the new ones. 
It requires the following fields.

CheckField[n]:  Will be a DynamiField Check that will be used to choose whether a subprocess to certain queue or area should be created.
Queue[n]: Will indicate the queue where the subprocess N should be placed.
fields[n]: Will be the Dynamic Fields to be copied into the new process N
activity[n]: Will be the (ActivityEntityID) next activity to be executed by the suprocess N.
process[n]: Will be the ProcessEntityID of the Process type the new subprocess should be of.
title[n]: Will be the Title of the subprocess N to be created. 

MergeTicket

It uses the module MergeTicket.pm and merges a process or subprocess into it’s parent ticket (process), copying all the information from the original one into the merged ticket. It requires the following fields:
fields: The fields that do not exist into the parent ticket and should be set at the merge time
article: An article indicating the reasons for the merge. 

