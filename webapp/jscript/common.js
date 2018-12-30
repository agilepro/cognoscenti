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
            console.log("PASTE:", args.content);
            //var modified = args.content.replace(new RegExp("<br ?/>", 'g'),"</p><p>");
            
            //args.content = modified;
            //console.log("MOD  :", args.content);
        },
        paste_as_text: false,
        browser_spellcheck: true,
        plugins: "link stylebuttons lists paste",
        inline: false,
        menubar: false,
        body_class: 'leafContent',
        statusbar: false,
        toolbar: "style-p, style-h1, style-h2, style-h3, bullist, outdent, indent | bold, italic, link |  cut, copy, paste, undo, redo",
        target_list: false,
        link_title: false
	};
}

