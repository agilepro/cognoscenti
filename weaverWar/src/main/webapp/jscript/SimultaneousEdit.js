/*

This is a library to support simultaneous/concurrent edit blocks of text that a user can be editing in the browser, and others can be editing elsewhere, and all the correct synchronization is performed.  

This class does two real things: 

(1) it helps to manage the markdown to html conversions needed for the HTML editor, and 
(2) it does the merge to markdown when an update comes from the server
(3) it holds the flag on whether the editor is open
(4) it holds a flag on whether we know of changes on the server not yet merged

The block of text is held in an object, with three main fields

{
    vServer:   this is markdown we got from the server, what we believe the server has
    vLocal:    this is markdown that is being locally edited by the user
    vHtml:     this is the html version of the local version that the editor works on
    isEditing  boolean flag whether user has editor open, avoid updates from server
    needsMerge boolean flag that we know there is a change on the server to pick up
    autoMerge  set to true to update editor while editing.  This is dangerous because if
               the editor is updated, the cursor will be moved somewhere.  I have not found
               a way to preserve the cursor position, so leave this false.
}

PATTERN OF USAGE

When you first get the markdown from the server, execute this:

    mySim = new SimText(markdown_from_server);
    
Display the html using something like this:

    <div ng-bind-html="mySim.vHtml"></div>

Edit with edit using something similar:

    <div ui-tinymce="tinymceOptions" ng-model="mySim.vHtml"></div>
    
Send an update to the server, you have to send two values, the oldMarkdown is what the server had when user started editing, and newMarkdown is the value that is currently in editor.  The user's changes is the difference between these two values.  Generally both are sent to the server.

    var newMarkdown = mySim.getLocal();   //a.k.a. lastSave
    var oldMarkdown = mySim.vServer;
    
When you receive a response from the server, you need to provide two values to the merge routine.  First the value you sent to the server to update to, and second the value that just came from the server.  The diff between these two are the changes on the server that need to be merged locally.

    mySim.updateFromServer( lastSave, newMarkdown );
    
Note, if marked for editing and not autoMerge, then the merge will not be done, but instead a flag needMerge is set saying that there are changes on the server.  If editing and autoMerge then a merge will be performed.  If not editing, then the new markdown will simply be set as the new local markdown and html.

TIME OF SAVE

The difference between vServer and vLocal is what user has typed since the last update from the server.
Note that as incremental updates are sent to the server, the vServer should be updated to 
the last saved, so that next save only has 

When it is time for the server to be updated, we both the vServer and the vLocal so that the server can tell what the user intended to change, and update its side using a three way merge.  The server only considers the differences between vServer and vLocal when updating the server data, ignoring any other differences.


RESPONSE FROM SERVER

Server returns a "newMarkdown" value to client.
The difference between newMarkdown and lastSave is the changes from the server
The difference between lastSave and vLocal is changes the user made since the call to update.

Generally we don't update while the user is editing, because such an update can cause the 
cursor to jump to the beginning, and that is really annoying.   So we keep track of whether 
the editor is open or not.

If the editor is open, then we don't update, and just mark the needsMerge flag, telling that 
there is a change on the server.   The change received is thrown away, on the assumption that 
when the user says to merge, a new call to the server will pick up all the recent changes.

There is a mode called autoMerge that will cause updates while the editor is open.  This is 
legacy capability and should probalby be left unused.

In any case, when the update results in the same markdown that the local already has, then 
the editor is not updated, so as to avoid unnecessary HTML updates to the editor.

*/


class SimText {
    constructor(newMarkdown) {
        this.init(newMarkdown);
    }
    init(newMarkdown) {
        this.vServer = newMarkdown;
        this.vLocal = newMarkdown;
        this.vHtml = convertMarkdownToHtml(newMarkdown);
        this.needMerge = false;
    }
    
    refreshHtml() {
        this.vLocal = HTML2Markdown(this.vHtml, {});
        this.vHtml = convertMarkdownToHtml(this.vLocal);
    }
    startEdit() {
        this.vHtml = convertMarkdownToHtml(this.vLocal);
        this.isEditing = true;
    }
    stopEdit() {
        //get the final edits from the html version
        this.vLocal = HTML2Markdown(this.vHtml, {});
        
        //refresh html to clean it up locally
        this.vHtml = convertMarkdownToHtml(this.vLocal);
        this.isEditing = false;
    }
    getLocal() {
        this.vLocal = HTML2Markdown(this.vHtml, {});
        return this.vLocal;
    }
    needsSaving() {
        this.vLocal = HTML2Markdown(this.vHtml, {});
        return this.vLocal;
    }
    updateFromServer(lastSave, newMarkdown) {
        if (!newMarkdown) {
            console.log("strange, no information about the new text from server");
            return;
        }
        
        //get the latest user edits back into the local as markdown
        this.vLocal = HTML2Markdown(this.vHtml, {});
        
        //if not editing, then just accept the new data without question
        //this assumes that the user had not made a change AND finished
        //since the last save attempt
        if (!this.isEditing) {
            this.init(newMarkdown);
            return;
        }
        
        if (lastSave == newMarkdown) {
            //nothing has changed on the server, so you
            //can ignore the update and don't update at all
            //whether user typing or not
            this.vServer = newMarkdown;
            return;
        } 
        
        if (newMarkdown == this.vLocal) {
            //weird special case where someone else made the same change
            //as the local user, so mark being back in sync
            this.vServer = newMarkdown;
            this.needMerge = false;
        }
        
        
        if (this.autoMerge) {
            //the automerge flag says to go ahead and merge changes WHILE the user
            //is editing even though this will usually cause the loss of cursor position
            var newLocal = Textmerger.get().merge(lastSave, this.vLocal, newMarkdown);
            this.vServer = newMarkdown;
            this.needMerge = false;
            if (this.vLocal != newLocal) {
                this.vLocal = newLocal;
                this.vHtml = convertMarkdownToHtml(newLocal);
            }
            return;
        }

        //all we can do is to signal that changes are on the server
        //but at least the server has seen recent changes so remember that
        this.needMerge = true;
        this.vServer = lastSave;
    }
    
    getBackgroundStyle() {
        if (this.needsMerge) {
            return {"background-color":"orange"};
        }
        else {
            return {"background-color":"white"};
        }
    }
}
