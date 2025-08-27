// Please add all the common function here.




/* INIT tinyMCE */
tinyMCE.PluginManager.add('stylebuttons', function(editor, url) {
    console.log("Running TinyMCE setup");
  ['p', 'h1', 'h2', 'h3'].forEach(function(name){
   editor.addButton("style-" + name, {
       tooltip: "Toggle " + name,
         text: name.toUpperCase(),
         onClick: function() { editor.execCommand('mceToggleFormat', false, name); },
         onPostRender: function() {
             var self = this, setup = function() {
                 editor.formatter.formatChanged(name, function(state) {
                     self.active(state);
                 });
             };
             editor.formatter ? setup() : editor.on('init', setup);
         }
     })
  });
});

function standardTinyMCEOptions() {
    console.log("Running standardTinyMCEOptions");
    return {
		handle_event_callback: function (e) {
		// put logic here for keypress
		},
        paste_preprocess: function(plugin, args) {
            //console.log("PASTE:", args.content);
        },
        paste_as_text: false,
        browser_spellcheck: true,
        plugins: "link stylebuttons lists paste",
        entity_encoding: "raw",
        inline: false,
        menubar: false,
        body_class: 'leafContent',
        statusbar: false,
        toolbar: "style-p, style-h1, style-h2, style-h3, bullist, outdent, indent | bold, italic, link |  cut, copy, paste, undo, redo",
        target_list: false,
        link_title: false
	};
}

//A filter is a string with words separated by spaces
//this function splits them, trims, and lowercases them
function parseLCList(str) {
    var res = [];
    if (!str) {
        return res;
    }
    str.split(" ").forEach( function(item) {
        var x = item.toLowerCase().trim();
        if (x.length>0) {
            res.push(x);
        }
    });
    return res;
}
//given a list of filter values, this returns whether
//the target string contains ALL the filter values
function containsOne(target, sourceArray) {
    if (!target) {
        return false;
    }
    var test = target.toLowerCase();
    for (var i=0; i<sourceArray.length; i++) {
        if (test.indexOf(sourceArray[i])<0) {
            return false;
        }
    }
    return true;
}

function superSplit(possibleList) {
    var res = [];
    while (possibleList.length>0) {
        var pos = possibleList.indexOf(",");
        var pos2 = possibleList.indexOf(";");
        if (pos2>0 && (pos2<pos || pos<0)) {
            pos = pos2;
        }
        var pos2 = possibleList.indexOf(" ");
        if (pos2>0 && (pos2<pos || pos<0)) {
            pos = pos2;
        }
        var pos2 = possibleList.indexOf("\n");
        if (pos2>0 && (pos2<pos || pos<0)) {
            pos = pos2;
        }
        if (pos<0) {
            var newVal = possibleList.trim();
            if (newVal) {
                res.push(newVal);
            }
            return res;
        }
        if (pos>=0) {
            var newVal = possibleList.substring(0,pos).trim();
            if (newVal) {
                res.push(newVal);
            }
            possibleList=possibleList.substring(pos+1).trim();
            while (possibleList.length>0 && (possibleList.charAt(0)==" " || possibleList.charAt(0)==","
                    || possibleList.charAt(0)==";" || possibleList.charAt(0)=="\n")) {
                possibleList=possibleList.substring(1).trim()
            }
        }
    }
    return res;
}

var VALID_EMAIL_ADDRESS_REGEX = /^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,6}$/;

function validateEmailAddress(emailStr) {
    if (VALID_EMAIL_ADDRESS_REGEX.test(emailStr.toLowerCase())) {
        return true;
    }
    else {
        console.log("BLOCKED invalid email address: ", emailStr);
        return false;
    }
}


/* takes a list of user objects, splits any that appear to 
have multiple email addresses into separate objects, and then
eliminates any duplications */
function cleanUserList(userList) {
    var expandList = [];
    userList.forEach( function(item) {
        var id = item.uid;
        if (!id) {
            id = item.name;
            item.uid = id;
        }
        var idList = superSplit(id);
        if (idList.length==1) {
            if (validateEmailAddress(id)) {
                expandList.push(item);
            }
        }
        else {
            idList.forEach( function(part) {
                if (validateEmailAddress(part)) {
                    expandList.push({uid:part,name:part});
                }
            });
        }
    });
    var cleanList = [];
    expandList.forEach( function(item) {
        var newOne = true;
        var uidlc = item.uid.toLowerCase();
        cleanList.forEach( function(inner) {
            if (uidlc == inner.uid.toLowerCase()) {
                newOne = false;
            }
        });
        if (newOne) {
            cleanList.push(item);
        }
    });
    return cleanList;
}

