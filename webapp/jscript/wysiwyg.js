/********************************************************************
 * openWYSIWYG v1.47 Copyright (c) 2006 openWebWare.com
 * Contact us at devs@openwebware.com
 * This copyright notice MUST stay intact for use.
 *
 * $Id: wysiwyg.js,v 1.41 2012/02/21 12:07:04 ajay Exp $
 * $Revision: 1.41 $
 *
 * An open source WYSIWYG editor for use in web based applications.
 * For full source code and docs, visit http://www.openwebware.com
 *
 * This library is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published
 * by the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public
 * License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License along
 * with this library; if not, write to the Free Software Foundation, Inc., 59
 * Temple Place, Suite 330, Boston, MA 02111-1307 USA
 ********************************************************************/
var WYSIWYG = {

  /**
   * Settings class, holds all customizeable properties
   */
  Settings: function() {

    // Images Directory
    this.ImagesDir = "../assets/";

    // Popups Directory
    this.PopupsDir = "../popups/";

    // CSS Directory File
    this.CSSFile = "../css/wysiwyg.css";

    // Default WYSIWYG width and height (use px or %)
    this.Width = "500px";
    this.Height = "200px";

    // Default stylesheet of the WYSIWYG editor window
    this.DefaultStyle = "font-family: Arial; font-size: 12px; background-color: #FFFFFF";

    // Stylesheet if editor is disabled
    this.DisabledStyle = "font-family: Arial; font-size: 12px; background-color: #EEEEEE";

    // Width + Height of the preview window
    this.PreviewWidth = 500;
    this.PreviewHeight = 400;

    // Confirmation message if you strip any HTML added by word
    this.RemoveFormatConfMessage = "Clean HTML inserted by MS Word ?";

    // Nofication if browser is not supported by openWYSIWYG, leave it blank for no message output.
    this.NoValidBrowserMessage = "openWYSIWYG does not support your browser.";

    // Anchor path to strip, leave it blank to ignore
    // or define auto to strip the path where the editor is placed
    // (only IE)
    this.AnchorPathToStrip = "auto";

    // Image path to strip, leave it blank to ignore
    // or define auto to strip the path where the editor is placed
    // (only IE)
    this.ImagePathToStrip = "auto";

    // Enable / Disable the custom context menu
    this.ContextMenu = true;

    // Enabled the status bar update. Within the status bar
    // node tree of the actually selected element will build
    this.StatusBarEnabled = true;

    // If enabled than the capability of the IE inserting line breaks will be inverted.
    // Normal: ENTER = <p> , SHIFT + ENTER = <br>
    // Inverted: ENTER = <br>, SHIFT + ENTER = <p>
    this.InvertIELineBreaks = true;

    // Replace line breaks with <br> tags
    this.ReplaceLineBreaks = false;

    // Page that opened the WYSIWYG (Used for the return command)
    this.Opener = "admin.asp";

    //Cursor position
    this.cursorPosition;
    this.selectionUtil;
    this.savedSelection;
    // Insert image implementation
    this.ImagePopupFile = "";
    this.ImagePopupWidth = 0;
    this.ImagePopupHeight = 0;

    // Holds the available buttons displayed
    // on the toolbar of the editor
    this.Toolbar = new Array();
    this.Toolbar[0] = new Array(
      "font",
      "fontsize",
      "headings",
      "bold",
      "italic",
      "underline",
      "strikethrough",
      "seperator",
      "forecolor",
      "backcolor",
      "seperator",
      "justifyfull",
      "justifyleft",
      "justifycenter",
      "justifyright",
      "seperator",
      "unorderedlist",
      "orderedlist",
      "outdent",
      "indent"
    );
    this.Toolbar[1] = new Array(
      "save",
      // "return",  // return button disabled by default
      "seperator",
      "subscript",
      "superscript",
      "seperator",
      "cut",
      "copy",
      "paste",
      "removeformat",
      "seperator",
      "undo",
      "redo",
      "seperator",
      "inserttable",
      "insertimage",
      "insertHorRule",
      "createlink",
      "seperator",
      "preview",
      "print",
      "seperator",
      "viewSource",
      "maximize",
      "seperator",
      "help"
    );

    // DropDowns
    this.DropDowns = new Array();
    // Fonts
    this.DropDowns['font'] = {
      id: "fonts",
      command: "FontName",
      label: "<font style=\"font-family:{value};font-size:12px;\">{value}</font>",
      width: "90px",
      elements: new Array(
        "Arial",
        "Sans Serif",
        "Tahoma",
        "Verdana",
        "Courier New",
        "Georgia",
        "Times New Roman",
        "Impact",
        "Comic Sans MS"
      )
    };
    // Font sizes
    this.DropDowns['fontsize'] = {
      id: "fontsizes",
      command: "FontSize",
      label: "<font size=\"{value}\">Size {value}</font>",
      width: "54px",
      elements: new Array(
        "1",
        "2",
        "3",
        "4",
        "5",
        "6",
        "7"
      )
    };
    // Headings
    this.DropDowns['headings'] = {
      id: "headings",
      command: "FormatBlock",
      label: "<{value} style=\"margin:0px;text-decoration:none;font-family:Arial\">{value}</{value}>",
      width: "74px",
      elements: new Array(
        "H1",
        "H2",
        "H3",
        "Normal"
      )
    };

    // Bullets
    this.DropDowns['bullets'] = {
      id: "bullets",
      command: "BulletsBlock",
      label: "<{value} style=\"margin:0px;text-decoration:none;font-family:Arial\">{value}</{value}>",
      width: "74px",
      elements: new Array(
        "Bullet 1",
        "Bullet 2",
        "Bullet 3"
      )
    };

    // Add the given element to the defined toolbar
    // on the defined position
    this.addToolbarElement = function(element, toolbar, position) {
      if(element != "seperator") {this.removeToolbarElement(element);}
      if(this.Toolbar[toolbar-1] == null) {
        this.Toolbar[toolbar-1] = new Array();
      }
      this.Toolbar[toolbar-1].splice(position+1, 1, element);
    };

    // Remove an element from the toolbar
    this.removeToolbarElement = function(element) {
      if(element == "seperator") {return;} // do not remove seperators
      for(var i=0;i<this.Toolbar.length;i++) {
        if(this.Toolbar[i]) {
          var toolbar = this.Toolbar[i];
          for(var j=0;j<toolbar.length;j++) {
            if(toolbar[j] != null && toolbar[j] == element) {
              this.Toolbar[i].splice(j,1);
            }
          }
        }
      }
    };

    // clear all or a given toolbar
    this.clearToolbar = function(toolbar) {
      if(typeof toolbar == "undefined") {
        this.Toolbar = new Array();
      }
      else {
        this.Toolbar[toolbar+1] = new Array();
      }
    };

  },


  /* ---------------------------------------------------------------------- *\
    !! Do not change something below or you know what you are doning !!
  \* ---------------------------------------------------------------------- */

  // List of available block formats (not in use)
  //BlockFormats: new Array("Address", "Bulleted List", "Definition", "Definition Term", "Directory List", "Formatted", "Heading 1", "Heading 2", "Heading 3", "Heading 4", "Heading 5", "Heading 6", "Menu List", "Normal", "Numbered List"),

  // List of available actions and their respective ID and images
  ToolbarList: {
  //Name              buttonID               buttonTitle             buttonImage               buttonImageRollover
  "bold":           ['Bold',                 'Bold',                 'bold.gif',               'bold_on.gif'],
  "italic":         ['Italic',               'Italic',               'italics.gif',            'italics_on.gif'],
  "underline":      ['Underline',            'Underline',            'underline.gif',          'underline_on.gif'],
  "strikethrough":  ['Strikethrough',        'Strikethrough',        'strikethrough.gif',      'strikethrough_on.gif'],
  "seperator":      ['',                     '',                     'seperator.gif',          'seperator.gif'],
  "subscript":      ['Subscript',            'Subscript',            'subscript.gif',          'subscript_on.gif'],
  "superscript":    ['Superscript',          'Superscript',          'superscript.gif',        'superscript_on.gif'],
  "justifyleft":    ['Justifyleft',          'Justifyleft',          'justify_left.gif',       'justify_left_on.gif'],
  "justifycenter":  ['Justifycenter',        'Justifycenter',        'justify_center.gif',     'justify_center_on.gif'],
  "justifyright":   ['Justifyright',         'Justifyright',         'justify_right.gif',      'justify_right_on.gif'],
  "justifyfull":     ['Justifyfull',        'Justifyfull',       'justify_justify.gif',     'justify_justify_on.gif'],
  "unorderedlist":  ['InsertUnorderedList',  'Insert Unordered List',  'list_unordered.gif',     'list_unordered_on.gif'],
  "orderedlist":    ['InsertOrderedList',    'Insert Ordered List',    'list_ordered.gif',       'list_ordered_on.gif'],
  "outdent":        ['Outdent',              'Outdent',              'indent_left.gif',        'indent_left_on.gif'],
  "indent":         ['Indent',               'Indent',               'indent_right.gif',       'indent_right_on.gif'],
  "cut":            ['Cut',                  'Cut',                  'cut.gif',                'cut_on.gif'],
  "copy":           ['Copy',                 'Copy',                 'copy.gif',               'copy_on.gif'],
  "paste":          ['Paste',                'Paste',                'paste.gif',              'paste_on.gif'],
  "forecolor":      ['ForeColor',            'Fore Color',            'forecolor.gif',          'forecolor_on.gif'],
  "backcolor":      ['BackColor',            'Back Color',            'backcolor.gif',          'backcolor_on.gif'],
  "undo":           ['Undo',                 'Undo',                 'undo.gif',               'undo_on.gif'],
  "redo":           ['Redo',                 'Redo',                 'redo.gif',               'redo_on.gif'],
  "inserttable":    ['InsertTable',          'Insert Table',          'insert_table.gif',       'insert_table_on.gif'],
  "insertHorRule":  ['inserthorizontalrule', 'Insert Horizontal Line','rule.png',               'rule.png'],
  "insertimage":    ['InsertImage',          'Insert Image',          'insert_picture.gif',     'insert_picture_on.gif'],
  "createlink":     ['CreateLink',           'Create Link',           'insert_hyperlink.gif',   'insert_hyperlink_on.gif'],
  "viewSource":     ['ViewSource',           'View Source',           'view_source.gif',        'view_source_on.gif'],
  "viewText":       ['ViewText',             'View Text',             'view_text.gif',          'view_text_on.gif'],
  "help":           ['Help',                 'Help',                 'help.gif',               'help_on.gif'],
  "fonts":         ['Fonts',                'Select Font',          'select_font.gif',        'select_font_on.gif'],
  "fontsizes":      ['Fontsizes',            'Select Size',          'select_size.gif',        'select_size_on.gif'],
  "headings":       ['Headings',             'Select Size',          'select_heading.gif',     'select_heading_on.gif'],
  "bullets":        ['Bullets',              'Select Size',          'select_bullets.gif',     'select_bullets_on.gif'],
  "preview":      ['Preview',          'Preview',            'preview.gif',        'preview_on.gif'],
  "print":      ['Print',          'Print',               'print.gif',        'print_on.gif'],
  "removeformat":   ['RemoveFormat',         'Convert to Plain text', 'remove_format.gif',      'remove_format_on.gif'],
  "delete":         ['Delete',               'Delete',               'delete.gif',           'delete_on.gif'],
  "save":       ['Save',            'Save document',         'save.gif',         'save_on.gif'],
  "return":       ['Return',          'Return without saving', 'return.gif',         'return_on.gif'],
  "h1":           ['H1',              'Make a header with value H1', 'H1.gif',             'H1_on.gif'],
  "h2":           ['H2',              'Make a header with value H2', 'H2.gif',             'H2_on.gif'],
  "h3":           ['H3',              'Make a header with value H3', 'H3.gif',             'H3_on.gif'],
  "bullet1":       ['Bullet 1',          'Make Bullet with one Indent', 'Bullet_1.gif',       'Bullet_1_on.gif'],
  "bullet2":       ['Bullet 2',          'Make Bullet with two Indents', 'Bullet_2.gif',       'Bullet_2_on.gif'],
  "bullet3":       ['Bullet 3',          'Make Bullet with three Indents', 'Bullet_3.gif',       'Bullet_3_on.gif'],
  "Normal":       ['Normal',          'Convert to Paragraph', 'P.gif',       'P_on.gif'],
  "maximize":     ['Maximize',          'Maximize the editor',   'maximize.gif',       'maximize_on.gif']
  },

  // stores the different settings for each textarea
  // the textarea identifier is used to store the settings object
  config: new Array(),
  // Create viewTextMode global variable and set to 0
  // enabling all toolbar commands while in HTML mode
  viewTextMode: new Array(),
  // maximized
  maximized: new Array(),

  /**
   * Get the range of the given selection
   *
   * @param {Selection} sel Selection object
   * @return {Range} Range object
   */
  getRange: function(sel) {
    return sel.createRange ? sel.createRange() : sel.getRangeAt(0);
  },

  /**
   * Return the editor div element
   *
   * @param {String} n Editor identifier
   * @return {HtmlDivElement} Iframe object
   */
  getEditorDiv: function(n) {
    return $("wysiwyg_div_" + n);
  },

  /**
   * Return the editor table element
   *
   * @param {String} n Editor identifier
   * @return {HtmlTableElement} Iframe object
   */
  getEditorTable: function(n) {
    return $("wysiwyg_table_" + n);
  },

  /**
   * Get the iframe object of the WYSIWYG editor
   *
   * @param {String} n Editor identifier
   * @return {HtmlIframeElement} Iframe object
   */
  getEditor: function(n) {
    return $("wysiwyg" + n);
  },

  /**
   * Get editors window element
   *
   * @param {String} n Editor identifier
   * @return {HtmlWindowElement} Html window object
   */
  getEditorWindow: function(n) {
    return this.getEditor(n).contentWindow;
  },

  /**
   * Attach the WYSIWYG editor to the given textarea element
   *
   * @param {String} id Textarea identifier (all = all textareas)
   * @param {Settings} settings the settings which will be applied to the textarea
   */
  attach: function(id, settings) {
    if(id != "all") {
      this.setSettings(id, settings);
      WYSIWYG_Core.includeCSS(this.config[id].CSSFile);
      WYSIWYG_Core.addEvent(window, "load", function generateEditor() {WYSIWYG._generate(id, settings);});
    }
    else {

      WYSIWYG_Core.addEvent(window, "load", function generateEditor() {WYSIWYG.attachAll(settings);});
    }
  },

  /**
   * Attach the WYSIWYG editor to all textarea elements
   *
   * @param {Settings} settings Settings to customize the look and feel
   */
  attachAll: function(settings) {
    var areas = document.getElementsByTagName("textarea");
    for(var i=0;i<areas.length;i++) {
      var id = areas[i].getAttribute("id");
      if(id == null || id == "") continue;
      this.setSettings(id, settings);
      WYSIWYG_Core.includeCSS(this.config[id].CSSFile);
      WYSIWYG._generate(id, settings);
    }
  },

  /**
   * Display an iframe instead of the textarea.
   * It's used as textarea replacement to display HTML.
   *
   * @param id Textarea identifier (all = all textareas)
   * @param settings the settings which will be applied to the textarea
   */
  display: function(id, settings) {
    if(id != "all") {
      this.setSettings(id, settings);
      WYSIWYG_Core.includeCSS(this.config[id].CSSFile);
      WYSIWYG_Core.addEvent(window, "load", function displayIframe() {WYSIWYG._display(id, settings);});
    }
    else {
      WYSIWYG_Core.addEvent(window, "load", function displayIframe() {WYSIWYG.displayAll(settings);});
    }
  },

  /**
   * Display an iframe instead of the textarea.
   * It's apply the iframe to all textareas found in the current document.
   *
   * @param settings Settings to customize the look and feel
   */
  displayAll: function(settings) {
    var areas = document.getElementsByTagName("textarea");
    for(var i=0;i<areas.length;i++) {
      var id = areas[i].getAttribute("id");
      if(id == null || id == "") continue;
      this.setSettings(id, settings);
      WYSIWYG_Core.includeCSS(this.config[id].CSSFile);
      WYSIWYG._display(id, settings);
    }
  },

  /**
   * Set settings in config array, use the textarea id as identifier
   *
   * @param n Textarea identifier (all = all textareas)
   * @param settings the settings which will be applied to the textarea
   */
  setSettings: function(n, settings) {
    if(typeof(settings) != "object") {
      this.config[n] = new this.Settings();
    }
    else {
      this.config[n] = settings;
    }
  },

  /**
   * Insert or modify an image
   *
   * @param {String} src Source of the image
   * @param {Integer} width Width
   * @param {Integer} height Height
   * @param {String} align Alignment of the image
   * @param {String} border Border size
   * @param {String} alt Alternativ Text
   * @param {Integer} hspace Horizontal Space
   * @param {Integer} vspace Vertical Space
   * @param {String} n The editor identifier (the textarea's ID)
   */
  insertImage: function(src, width, height, align, border, alt, hspace, vspace, n) {

    // get editor
    var doc = this.getEditorWindow(n).document;
    // get selection and range
    var sel = this.getSelection(n);
    var range = this.getRange(sel);

    // the current tag of range
    var img = this.findParent("img", range);

    // element is not a link
    var update = (img == null) ? false : true;
    if(!update) {
      img = doc.createElement("img");
    }

    // set the attributes
    WYSIWYG_Core.setAttribute(img, "src", src);
    WYSIWYG_Core.setAttribute(img, "style", "width:" + width + ";height:" + height);
    if(align != "") { WYSIWYG_Core.setAttribute(img, "align", align); } else { img.removeAttribute("align"); }
    WYSIWYG_Core.setAttribute(img, "border", border);
    WYSIWYG_Core.setAttribute(img, "alt", alt);
    WYSIWYG_Core.setAttribute(img, "hspace", hspace);
    WYSIWYG_Core.setAttribute(img, "vspace", vspace);
    img.removeAttribute("width");
    img.removeAttribute("height");

    // on update exit here
    if(update) { return; }

    // Check if IE or Mozilla (other)
    if (WYSIWYG_Core.isMSIE) {
      range.pasteHTML(img.outerHTML);
    }
    else {
      this.insertNodeAtSelection(img, n);
    }
  },

  /**
   * Insert or modify a link
   *
   * @param {String} href The url of the link
   * @param {String} target Target of the link
   * @param {String} style Stylesheet of the link
   * @param {String} styleClass Stylesheet class of the link
   * @param {String} name Name attribute of the link
   * @param {String} n The editor identifier (the textarea's ID)
   */
  insertLink: function(href,name, n) {

    // get editor
    var doc = this.getEditorWindow(n).document;
    // get selection and range
    var sel = this.getSelection(n);
    var range = this.getRange(sel);
    var lin = null;
    // get element from selection
    if(WYSIWYG_Core.isMSIE) {
      if(sel.type == "Control" && range.length == 1) {
        range = this.getTextRange(range(0));
        range.select();
      }
    }
    // find a as parent element
    lin = this.findParent("a", range);
    // check if parent is found
    var update = (lin == null) ? false : true;
    if(!update) {
      lin = doc.createElement("a");
    }

     // set the attributes
    WYSIWYG_Core.setAttribute(lin, "href", href);
    // on update exit here
    if(update) { return; }

    // Check if IE or Mozilla (other)
    if (WYSIWYG_Core.isMSIE) {
      range.select();
      lin.innerHTML = range.htmlText;
      range.pasteHTML(lin.outerHTML);
    }
    else {
      var node = range.startContainer;

      var pos = range.startOffset;
      if(node.nodeType != 3) { node = node.childNodes[pos]; }

        if(sel==null || sel=='')
          lin.innerHTML = name;
        else
          lin.innerHTML = sel;
      this.insertNodeAtSelection(lin, n);
    }
  },

  /**
   * Strips any HTML added by word
   *
     * @param {String} n The editor identifier (the textarea's ID)
   */
  removeFormat: function(n) {
//  if ( !confirm(this.config[n].RemoveFormatConfMessage) ) { return; }
    var doc = this.getEditorWindow(n).document;
    var str = doc.body.innerHTML;
    //var str = this.getSelection(n);

    var aTagName="style";
    regexp= new RegExp ("<" + aTagName + "[^.]*\/" + aTagName + ">", "gi");
    str = str.replace(regexp,"");

    try{
      str=str.trim();
    }
    catch(e){
      //do nothing
    }
    while(str.match('<span style=\"font-weight: bold;\">(.*?)<\/span>')){
      var boldInFF = str.match('<span style=\"font-weight: bold;\">(.*?)<\/span>');

      if(boldInFF != null && boldInFF.length>1){
        str = str.replace('<span style=\"font-weight: bold;\">'+boldInFF[1]+'<\/span>', 'b0ld_'+boldInFF[1]+'_b0ld');

      }
    }

    while(str.match('<span style=\"font-style: italic;\">(.*?)<\/span>')){

      var italicsInFF = str.match('<span style=\"font-style: italic;\">(.*?)<\/span>');
      if(italicsInFF != null && italicsInFF.length>1){
        str = str.replace('<span style=\"font-style: italic;\">'+italicsInFF[1]+'<\/span>', 'ital1c_'+italicsInFF[1]+'_ital1c');
      }
    }

    while(str.match('<i style=\"font-weight: bold;\">(.*?)<\/i>')){
      var boldOverItalicsInFF = str.match('<i style=\"font-weight: bold;\">(.*?)<\/i>');
      if(boldOverItalicsInFF != null && boldOverItalicsInFF.length>1){
        str = str.replace('<i style=\"font-weight: bold;\">'+boldOverItalicsInFF[1]+'<\/i>', 'b0ld_ital1c_'+boldOverItalicsInFF[1]+'_ital1c_b0ld');
      }

    }


    while(str.match('<b style=\"font-style: italic;\">(.*?)<\/b>')){

      var italicsOverBoldInFF = str.match('<b style=\"font-style: italic;\">(.*?)<\/b>');

      if(italicsOverBoldInFF != null && italicsOverBoldInFF.length>1){
        str = str.replace('<b style=\"font-style: italic;\">'+italicsOverBoldInFF[1]+'<\/b>', 'b0ld_ital1c_'+italicsOverBoldInFF[1]+'_ital1c_b0ld');
      }


    }

    while(str.match('<span style=\"font-weight: bold; font-style: italic;\">(.*?)<\/span>')){

      var italicsBoldInFF = str.match('<span style=\"font-weight: bold; font-style: italic;\">(.*?)<\/span>');
      if(italicsBoldInFF != null && italicsBoldInFF.length>1){
        str = str.replace('<span style=\"font-weight: bold; font-style: italic;\">'+italicsBoldInFF[1]+'<\/span>', 'b0ld_ital1c_'+italicsBoldInFF[1]+'_ital1c_b0ld');
      }

    }





    str = this._replaceAll(str,'<b>','b0ld_');
    str = this._replaceAll(str,'<\/b>','_b0ld');
    str = this._replaceAll(str,'<i>','ital1c_');
    str = this._replaceAll(str,'<\/i>','_ital1c');


    var SecondLevelIndent = str.match('<ul style=\"margin-left: 40px;\"><li>(.*?)<\/li><\/ul>');

    if(SecondLevelIndent!=null && SecondLevelIndent.length>1){
      str = str.replace('<ul style=\"margin-left: 40px;\"><li>'+SecondLevelIndent[1]+'<\/li><\/ul>', '<ul><ul><li>'+SecondLevelIndent[1]+'</li></ul></ul>');
    }

    var ThirdLevelIndent = str.match('<ul style=\"margin-left: 80px;\"><li>(.*?)<\/li><\/ul>');

    if(ThirdLevelIndent!=null && ThirdLevelIndent.length>1){
      str = str.replace('<ul style=\"margin-left: 80px;\"><li>'+ThirdLevelIndent[1]+'<\/li><\/ul>', '<ul><ul><ul><li>'+ThirdLevelIndent[1]+'</li></ul></ul></ul>');
    }


    str = this._replaceAll(str,'b0ld_', '<b>');
    str = this._replaceAll(str,'_b0ld','<\/b>');
    str = this._replaceAll(str,'ital1c_','<i>');
    str = this._replaceAll(str,'_ital1c','<\/i>');

    str = str.replace(/<span([^>])*>(&nbsp;)*\s*<\/span>/gi, '');

      str = str.replace(/<span[^>]*>/gi, '');
      str = str.replace(/<\/span[^>]*>/gi, '');
  //    str = str.replace(/<p([^>])*>(&nbsp;)*\s*<\/p>/gi, '');
      str = str.replace(/<blockquote([^>])*>/gi, '');

   //   str = str.replace(/<\/p[^>]*>/gi, '');
      str = str.replace(/<h([^>])[4-9]>(&nbsp;)*\s*<\/h>/gi, '');
      str = str.replace(/<h[^>][4-9]>/gi, '');
      str = str.replace(/<\/h[^>][4-9]>/gi, '');
    str = str.replace (/<B [^>]*>/ig, '<b>');
    str = str.replace(/<style>.*<\/style>/gi, '');
    // var repl_i1 = /<I[^>]*>/ig;
    // str = str.replace (repl_i1, '<i>');

    str = str.replace (/<DIV[^>]*>/ig, '');
    str = str.replace (/<\/DIV>/gi, '');
    str = str.replace (/<[\/\w?]+:[^>]*>/ig, '');
    str = str.replace (/(&nbsp;){2,}/ig, '&nbsp;');
  //  str = str.replace (/<STRONG>/ig, '');
//    str = str.replace (/<\/STRONG>/ig, '');
    str = str.replace (/<TT>/ig, '');
    str = str.replace (/<\/TT>/ig, '');
    str = str.replace (/<FONT [^>]*>/ig, '');
    str = str.replace (/<\/FONT>/ig, '');
    str = str.replace (/STYLE=\"[^\"]*\"/ig, '');
    str = str.replace(/<([\w]+) class=([^ |>]*)([^>]*)/gi, '<$1$3');
        str = str.replace(/<([\w]+) style="([^"]*)"([^>]*)/gi, '<$1$3');
    str = str.replace(/width=([^ |>]*)([^>]*)/gi, '');
      str = str.replace(/classname=([^ |>]*)([^>]*)/gi, '');
      str = str.replace(/align=([^ |>]*)([^>]*)/gi, '');
      str = str.replace(/valign=([^ |>]*)([^>]*)/gi, '');
      str = str.replace(/<\\?\??xml[^>]>/gi, '');
      str = str.replace(/<\/?\w+:[^>]*>/gi, '');
      str = str.replace(/<st1:.*?>/gi, '');
      str = str.replace(/<o:/gi, '');
      str = str.replace(/<w:/gi, '');
      str = str.replace(/<w:([^>])*>(&nbsp;)*\s*<\/w:([^>])*>/gi, '');
      str = str.replace(/<!--([^>])*>(&nbsp;)*\s*<\/-->/gi, '');
       str = str.replace(/<!--[^>]*>/gi, '');
       str = str.replace(/<![^>]*-->/gi, '');
       str = str.replace(/<\/--[^>]*>/gi, '');
    str = str.replace(/<style([^>])*>(&nbsp;)*\s*<\/style>/gi, '');
      str=str.replace(/<style( >])*>(.*?)<\/style>/gi,'');
    doc.body.innerHTML = str;

  },

  _replaceAll: function(Source,stringToFind,stringToReplace){
      var temp = Source;
        var index = temp.indexOf(stringToFind);
            while(index != -1){
                temp = temp.replace(stringToFind,stringToReplace);
                index = temp.indexOf(stringToFind);
            }
            return temp;
    },

  /**
   * Display an iframe instead of the textarea.
   *
   * @private
   * @param {String} n The editor identifier (the textarea's ID)
   * @param {Object} settings Object which holds the settings
   */
  _display: function(n, settings) {

    // Get the textarea element
    var textarea = $(n);

    // Validate if textarea exists
    if(textarea == null) {
      alert("No textarea found with the given identifier (ID: " + n + ").");
      return;
    }

    // Validate browser compatiblity
    if(!WYSIWYG_Core.isBrowserCompatible()) {
      if(this.config[n].NoValidBrowserMessage != "") { alert(this.config[n].NoValidBrowserMessage); }
      return;
    }

      // Load settings in config array, use the textarea id as identifier
    if(typeof(settings) != "object") {
      this.config[n] = new this.Settings();
    }
    else {
      this.config[n] = settings;
    }

    // Hide the textarea
    textarea.style.display = "none";

    // Override the width and height of the editor with the
    // size given by the style attributes width and height
    if(textarea.style.width) {
      this.config[n].Width = textarea.style.width;
    }
    if(textarea.style.height) {
      this.config[n].Height = textarea.style.height
    }

      // determine the width + height
    var currentWidth = this.config[n].Width;
    var currentHeight = this.config[n].Height;

    // Calculate the width + height of the editor
    var ifrmWidth = "100%";
    var  ifrmHeight = "100%";
    if(currentWidth.search(/%/) == -1) {
      ifrmWidth = currentWidth;
      ifrmHeight = currentHeight;
    }

    // Create iframe which will be used for rich text editing
    var iframe = '<table cellpadding="0" cellspacing="0" border="0" style="width:' + currentWidth + '; height:' + currentHeight + ';" class="tableTextareaEditor"><tr><td valign="top">\n'
      + '<iframe frameborder="0" id="wysiwyg' + n + '" class="iframeText" style="width:' + ifrmWidth + ';height:' + ifrmHeight + ';"></iframe>\n'
      + '</td></tr></table>\n';

      // Insert after the textArea both toolbar one and two
    textarea.insertAdjacentHTML("afterEnd", iframe);

    // Pass the textarea's existing text over to the content variable
      var content = textarea.value;
    var doc = this.getEditorWindow(n).document;

    // Replace all \n with <br>
    if(this.config[n].ReplaceLineBreaks) {
      content = content.replace(/(\r\n)|(\n)/ig, "<br>");
    }

    // Write the textarea's content into the iframe
      doc.open();
      doc.write(content);
      doc.close();

      // Set default style of the editor window
    WYSIWYG_Core.setAttribute(doc.body, "style", this.config[n].DefaultStyle);
  },

  /**
   * Replace the given textarea with wysiwyg editor
   *
   * @private
   * @param {String} n The editor identifier (the textarea's ID)
   * @param {Object} settings Object which holds the settings
   */
  _generate: function(n, settings) {

    // Get the textarea element
    var textarea = $(n);
    // Validate if textarea exists
    if(textarea == null) {
      alert("No textarea found with the given identifier (ID: " + n + ").");
      return;
    }

    // Validate browser compatiblity
    if(!WYSIWYG_Core.isBrowserCompatible()) {
      if(this.config[n].NoValidBrowserMessage != "") { alert(this.config[n].NoValidBrowserMessage); }
      return;
    }

    // Hide the textarea
    textarea.style.display = 'none';

    // Override the width and height of the editor with the
    // size given by the style attributes width and height
    if(textarea.style.width) {
      this.config[n].Width = textarea.style.width;
    }
    if(textarea.style.height) {
      this.config[n].Height = textarea.style.height
    }

      // determine the width + height
    var currentWidth = this.config[n].Width;
    var currentHeight = this.config[n].Height;

    // Calculate the width + height of the editor
    var toolbarWidth = currentWidth;
    var ifrmWidth = "100%";
    var  ifrmHeight = "100%";
    if(currentWidth.search(/%/) == -1) {
      toolbarWidth = currentWidth.replace(/px/gi, "");
      toolbarWidth = (parseFloat(toolbarWidth) + 2) + "px";
      ifrmWidth = currentWidth;
      ifrmHeight = currentHeight;
    }

      // Generate the WYSIWYG Table
      // This table holds the toolbars and the iframe as the editor
      var editor = "";
      editor += '<div class="div_table" id="wysiwyg_div_' + n + '" style="width:' + currentWidth  +';">';
      editor += '<table border="0" cellpadding="0" cellspacing="0" class="tableTextareaEditor" id="wysiwyg_table_' + n + '" style="width:' + currentWidth  + '; height:' + currentHeight + ';">';
      editor += '<tr><td style="height:22px;vertical-align:top;">';

    // Output all command buttons that belong to toolbar one
    for (var j = 0; j < this.config[n].Toolbar.length;j++) {
      if(this.config[n].Toolbar[j] && this.config[n].Toolbar[j].length > 0) {
        var toolbar = this.config[n].Toolbar[j];

        // Generate WYSIWYG toolbar one
          editor += '<table border="0" cellpadding="0" cellspacing="0" class="toolbar1" style="width:100%;" id="toolbar' + j + '_' + n + '">';
          editor += '<tr><td style="width:6px;"><img src="' + this.config[n].ImagesDir + 'seperator2.gif" alt="" hspace="3"></td>';

        // Interate over the toolbar element
        for (var i = 0; i < toolbar.length;i++) {
          var id = toolbar[i];
            if (toolbar[i]) {
              if(typeof (this.config[n].DropDowns[id]) != "undefined") {
                var dropdown = this.config[n].DropDowns[id];
                editor += '<td style="width: ' + dropdown.width + ';">';
                // write the drop down content
                editor += this.writeDropDown(n, id);
                editor += '</td>';
              }
              else {

                // Get the values of the Button from the global ToolbarList object
              var buttonObj = this.ToolbarList[toolbar[i]];
              if(buttonObj) {
                var buttonID = buttonObj[0];
                var buttonTitle = buttonObj[1];
                var buttonImage = this.config[n].ImagesDir + buttonObj[2];
                var buttonImageRollover  = this.config[n].ImagesDir + buttonObj[3];

                if (toolbar[i] == "seperator") {
                  editor += '<td style="width: 12px;" align="center">';
                  editor += '<img src="' + buttonImage + '" border=0 unselectable="on" width="2" height="18" hspace="2" unselectable="on">';
                  editor += '</td>';
                }
                // View Source button
                else if (toolbar[i] == "viewSource"){
                    editor += '<td style="width: 22px;">';
                  editor += '<span id="HTMLMode' + n + '"><img src="' + buttonImage +  '" border="0" unselectable="on" title="' + buttonTitle + '" id="' + buttonID + '" class="buttonEditor" onmouseover="this.className=\'buttonEditorOver\'; this.src=\'' + buttonImageRollover + '\';" onmouseout="this.className=\'buttonEditor\'; this.src=\'' + buttonImage + '\';" onclick="WYSIWYG.execCommand(\'' + n + '\', \'' + buttonID + '\');" unselectable="on" width="20" height="20"></span>';
                  editor += '<span id="textMode' + n + '"><img src="' + this.config[n].ImagesDir + 'view_text.gif" border="0" unselectable="on" title="viewText" id="ViewText" class="buttonEditor" onmouseover="this.className=\'buttonEditorOver\'; this.src=\'' + this.config[n].ImagesDir + 'view_text_on.gif\';" onmouseout="this.className=\'buttonEditor\'; this.src=\'' + this.config[n].ImagesDir + 'view_text.gif\';" onclick="WYSIWYG.execCommand(\'' + n + '\',\'ViewText\');" unselectable="on"  width="20" height="20"></span>';
                      editor += '</td>';
                    }
                else {
                  editor += '<td style="width: 22px;">';
                  editor += '<img src="' + buttonImage + '" border=0 unselectable="on" title="' + buttonTitle + '" id="' + buttonID + '" class="buttonEditor" onmouseover="this.className=\'buttonEditorOver\'; this.src=\'' + buttonImageRollover + '\';" onmouseout="this.className=\'buttonEditor\'; this.src=\'' + buttonImage + '\';" onclick="WYSIWYG.execCommand(\'' + n + '\', \'' + buttonID + '\');" unselectable="on" width="20" height="20">';
                  editor += '</td>';
                }
              }
            }
            }
          }
          editor += '<td>&nbsp;</td></tr></table>';
      }
    }

     editor += '</td></tr><tr><td valign="top">\n';
    // Create iframe which will be used for rich text editing
    editor += '<iframe frameborder="0" id="wysiwyg' + n + '" class="iframeText" style="width:100%;height:' + currentHeight + ';"></iframe>\n'
      + '</td></tr>';
      // Status bar HTML code
      if(this.config[n].StatusBarEnabled) {
        editor += '<tr><td class="wysiwyg-statusbar" style="height:10px;" id="wysiwyg_statusbar_' + n + '">&nbsp;</td></tr>';
    }
      editor += '</table>';
      editor += '</div>';

      // Insert the editor after the textarea
      textarea.insertAdjacentHTML("afterEnd", editor);

    // Hide the "Text Mode" button
    // Validate if textMode Elements are prensent
    if($("textMode" + n)) {
      $("textMode" + n).style.display = 'none';
    }

    // Pass the textarea's existing text over to the content variable
      var content = textarea.value;
    var doc = this.getEditorWindow(n).document;


    // Replace all \n with <br>
    if(this.config[n].ReplaceLineBreaks) {
      content = content.replace(/\n\r|\n/ig, "<br>");
    }

    // Write the textarea's content into the iframe
      doc.open();
      doc.write(content);
      doc.close();

    // Make the iframe editable in both Mozilla and IE
    // Improve compatiblity for IE + Mozilla
    if (doc.body.contentEditable) {
      doc.body.contentEditable = true;
    }
    else {
      doc.designMode = "on";
    }

    // Set default font style
    //WYSIWYG_Core.setAttribute(doc.body, "style", this.config[n].DefaultStyle);

    // Enable table highlighting
    WYSIWYG_Table.refreshHighlighting(n);

      // Event Handling
      // Update the textarea with content in WYSIWYG when user submits form
      for (var idx=0; idx < document.forms.length; idx++) {
      //  WYSIWYG_Core.addEvent(document.forms[idx], "submit", function xxx_aa() { WYSIWYG.updateTextArea(n); });
      }

      WYSIWYG_Core.addEvent(doc, "keydown", function xxx_chnge() { changeInNote=true;});

      // close font selection if mouse moves over the editor window
      WYSIWYG_Core.addEvent(doc, "mouseover", function xxx_bb() { WYSIWYG.closeDropDowns(n);});

      //WYSIWYG_Core.addEvent(doc, "keypress", function xxx_remove() { WYSIWYG.parseAndremoveUnwanted(n);});
      if(WYSIWYG_Core.isFF){
        WYSIWYG_Core.addEvent(doc, "keypress", function xxx_ee(e) {return WYSIWYG.invertIELineBreakCapabilityGeneric(n,e); });
      }

      // If it's true invert the line break capability of IE
    if(this.config[n].InvertIELineBreaks && !WYSIWYG_Core.isFF) {
      WYSIWYG_Core.addEvent(doc, "keypress", function xxx_cc() { WYSIWYG.invertIELineBreakCapability(n); });
    }

    // status bar update
    if(this.config[n].StatusBarEnabled) {
      WYSIWYG_Core.addEvent(doc, "mouseup", function xxx_dd() { WYSIWYG.updateStatusBar(n); });
    }

      // custom context menu
    if(this.config[n].ContextMenu) {
      //WYSIWYG_ContextMenu.init(n);
    }

    // init viewTextMode var
      this.viewTextMode[n] = false;
  },

  highlight: function() {
    var colour ="red";
      var range, sel;
      if (window.getSelection) {
          // Non-IE case
          sel = window.getSelection();
          if (sel.getRangeAt) {
              range = sel.getRangeAt(0);
          }
          document.designMode = "on";
          if (range) {
              sel.removeAllRanges();
              sel.addRange(range);
          }
          // Use HiliteColor since some browsers apply BackColor to the whole block
          if ( !document.execCommand("HiliteColor", false, colour) ) {
              document.execCommand("BackColor", false, colour);
          }
          document.designMode = "off";
      } else if (document.selection && document.selection.createRange) {
          // IE case
          range = document.selection.createRange();
          range.execCommand("BackColor", false, colour);
      }
  },


  /**
   * Disable the given WYSIWYG Editor Box
   *
   * @param {String} n The editor identifier (the textarea's ID)
   */
  disable: function(n) {

    // get the editor window
    var editor = this.getEditorWindow(n);

    // Validate if editor exists
    if(editor == null) {
      alert("No editor found with the given identifier (ID: " + n + ").");
      return;
    }

    if(editor) {
      // disable design mode or content editable feature
      if(editor.document.body.contentEditable) {
        editor.document.body.contentEditable = false;
      }
      else {
        editor.document.designMode = "Off";
      }

      // change the style of the body
      WYSIWYG_Core.setAttribute(editor.document.body, "style", this.config[n].DisabledStyle);

      // hide the status bar
      this.hideStatusBar(n);

      // hide all toolbars
      this.hideToolbars(n);
    }
  },

  /**
   * Enables the given WYSIWYG Editor Box
   *
   * @param {String} n The editor identifier (the textarea's ID)
   */
  enable: function(n) {

    // get the editor window
    var editor = this.getEditorWindow(n);

    // Validate if editor exists
    if(editor == null) {
      alert("No editor found with the given identifier (ID: " + n + ").");
      return;
    }

    if(editor) {
      // disable design mode or content editable feature
      if(editor.document.body.contentEditable){
        editor.document.body.contentEditable = true;
      }
      else {
        editor.document.designMode = "On";
      }

      // change the style of the body
      WYSIWYG_Core.setAttribute(editor.document.body, "style", this.config[n].DefaultStyle);

      // hide the status bar
      this.showStatusBar(n);

      // hide all toolbars
      this.showToolbars(n);
    }
  },

  /**
   * Returns the node structure of the current selection as array
   *
   * @param {String} n The editor identifier (the textarea's ID)
   */
  getNodeTree: function(n) {

    var sel = this.getSelection(n);
    var range = this.getRange(sel);

    // get element of range
    var tag = this.getTag(range);
    if(tag == null) { return; }
    // get parent of element
    var node = this.getParent(tag);
    // init the tree as array with the current selected element
    var nodeTree = new Array(tag);
    // get all parent nodes
    var ii = 1;

    while(node != null && node.nodeName != "#document") {
      nodeTree[ii] = node;
      node = this.getParent(node);
      ii++;
    }

    return nodeTree;
  },

  /**
   * Removes the current node of the selection
   *
   * @param {String} n The editor identifier (the textarea's ID)
   */
  removeNode: function(n,command) {

    var sel = this.getSelection(n);
    if(command==null || typeof(command)=='undefined')
      command=false;
    var range = this.getRange(sel);
    // the current tag of range
    var  tag = this.getTag(range);

    var parent;
    if(tag != null){
      parent = tag.parentNode;
    }
    if(tag == null || parent == null) { return; }
    if(tag.nodeName == "HTML" || tag.nodeName == "BODY") { return; }

    // copy child elements of the node to the parent element before remove the node
    var childNodes = new Array();
    var doc = this.getEditorWindow(n).document;
    var paragraphTag = doc.createElement('p');

    for(var i=0; i < tag.childNodes.length;i++){
      childNodes[i] = tag.childNodes[i];
    }
    if(command==false && (tag.nodeName=="H1" || tag.nodeName=="H2" || tag.nodeName=="H3")){
      for(var i=0; i < childNodes.length;i++){

        paragraphTag.appendChild(childNodes[i]);
      }
      //paragraphTag.innerHTML = tag.innerHTML;
      tag.parentNode.replaceChild(paragraphTag,tag);

      tag.focus();
      //select that node as we have to make it bullet now. so focus must be on that tag
/*      if(WYSIWYG_Core.isFF) {
        range.selectNode(paragraphTag);
        range.deSelectNode(paragraphTag);
      }
      else{
        range.select();
      }*/
    }
    else if( tag.nodeName=="UL" || tag.nodeName=="LI" ){
      this.removeBulletsForHeaders(n);
      if(WYSIWYG_Core.isFF) {
        WYSIWYG_Core.execCommand(n, "InsertParagraph","");
      }
    }
    else{
      for(var i=0; i < childNodes.length;i++){
        parent.insertBefore(childNodes[i], tag);
      }
      parent.removeChild(tag);
    }

    // validate if parent is a link and the node is only
    // surrounded by the link, then remove the link too
    if(parent.nodeName == "A" && !parent.hasChildNodes()) {
      if(parent.parentNode) { parent.parentNode.removeChild(parent); }
    }
    // update the status bar
    this.updateStatusBar(n);
  },


  /**
   * Removes the unwanted tags from DOM. Idea is simple iterate through all the child nodes of each node
   * Check if tag is legal then go on otherwise shift all the children to parent tag and remove that node.
   * This need a recursive function to iterate and a method that can verify whether tag is legal or not.
   *
   * @param {String} n The editor identifier (the textarea's ID)
   */
  parseAndremoveUnwanted: function(n,command) {

    var sel = this.getSelection(n);
    var range = this.getRange(sel);
    // the current tag of range
    var  tag = this.getTag(range);
    var doc = this.getEditorWindow(n).document;
    this.handleBodyChild(n,doc.body);
    this.updateStatusBar(n);
  },


  handleBodyChild: function(n,tag)
  {
    var childNodes = tag.childNodes;

    this.stripStyleAttribute(n,tag);

    // call a method to strip all attributes except for span and a tag and UL as well.
    for(var i=0;i<childNodes.length;i++){

      var nodeName = childNodes[i].nodeName;

      if(nodeName == "SPAN"){
          try{
            var newTag = null;
            var  node = childNodes[i];
          if(WYSIWYG_Core.isFF){
            newTag = this.handleBoldAndItalicsInStyle(n,childNodes[i],tag)
          }
            if(newTag!="undefined" && newTag!=null){
              tag.replaceChild(newTag,node);
            }
            else
            {
                    var node =childNodes[i];
                  var grandChildNodes = new Array();
                  var grandChildNodesSize = grandChildNodes.length;

                  for(var k=0; k < childNodes[i].childNodes.length;k++)
                  {
                      grandChildNodes[k] = childNodes[i].childNodes[k];
                  }
                  for(var j=grandChildNodes.length-1; j >=0;j--)
                  {
                    try{
                      tag.insertBefore(grandChildNodes[j],childNodes[i]);
                    }
                    catch(e){
                      alert(e);
                    }
                  }
                  tag.removeChild(node);
              }
          }
          catch(e){
            alert(e);
          }
      }
      else if(nodeName=="style" || nodeName=="xml" || nodeName=="br")
      {
        tag.removeChild(childNodes[i]);
      }
      else if ( nodeName == "P" || nodeName == "H1" || nodeName == "H2" || nodeName == "H3") {
         this.cleanInsideBlock(n,childNodes[i])
       }
       else if ( nodeName == "UL") {
          this.cleanInsideUL(n,childNodes[i],tag)
       }
       else if ( nodeName == "HR") {
          continue;
       }
       else if (nodeName == "STRONG" || nodeName == "EM" || nodeName == "B" || nodeName == "I" || nodeName == "A" || nodeName == "#text")
       {
         var childNode = childNodes[i];
         var newTag = null;
        if(WYSIWYG_Core.isFF){
          newTag = this.handleBoldAndItalicsInStyle(n,childNode,tag)
        }

           try{
             if(newTag!="undefined" && newTag!=null){
              tag.replaceChild(newTag,childNode);
              newTag.appendChild(childNode);
            }
          }
          catch(e){
            alert(e);
          }


         var doc = this.getEditorWindow(n).document;
        var paragraphTag = doc.createElement('P');

        try{
          if(newTag!=undefined && newTag!=null){
            tag.replaceChild(paragraphTag,newTag);
            paragraphTag.appendChild(newTag);
          }else{
            tag.replaceChild(paragraphTag,childNode);
            paragraphTag.appendChild(childNode);
          }

        }
        catch(e){
          alert(e);
        }
        this.cleanInsideBlock(n,paragraphTag)
       }
       else {
       var node =childNodes[i];
        var grandChildNodes = new Array();
        var grandChildNodesSize = grandChildNodes.length;

          for(var k=0; k < childNodes[i].childNodes.length;k++){
            grandChildNodes[k] = childNodes[i].childNodes[k];
          }
          for(var j=grandChildNodes.length-1; j >=0;j--)
          {
            try{
              tag.insertBefore(grandChildNodes[j],childNodes[i]);
            }
            catch(e){
              alert(e);
            }
          }
        tag.removeChild(node);
        this.handleBodyChild(n,tag);
       }
    }

  },





  handleBoldAndItalicsInStyle: function(n,node,tag){
        var spanStyle= node.style;
        var doc = this.getEditorWindow(n).document;
        var isBold = false;
        var boldTag = null;
        if(spanStyle==undefined || spanStyle==null){
          return null;
        }

        if(spanStyle.getPropertyValue("font-weight")=="bold" && spanStyle.getPropertyValue("font-style")=="italic"){


          boldTag = doc.createElement('B');
          var italicsTag = doc.createElement('I');
          var grandChildNodes = new Array();

          for(var k=0; k < node.childNodes.length;k++){
            grandChildNodes[k] = node.childNodes[k];
          }

          for(var j=grandChildNodes.length-1; j >=0;j--)
          {
            try{
              italicsTag.appendChild(grandChildNodes[j]);
            }
            catch(e){
              alert(e);
            }
          }
          boldTag.appendChild(italicsTag);


          isBold=true;
          return boldTag;
        }
        else if(spanStyle.getPropertyValue("font-weight")=="bold" && spanStyle.getPropertyValue("font-style")!="italic"){


          boldTag = doc.createElement('b');
          var grandChildNodes = new Array();

          for(var k=0; k < node.childNodes.length;k++){
            grandChildNodes[k] = node.childNodes[k];
          }

          for(var j=grandChildNodes.length-1; j >=0;j--)
          {
            try{
              boldTag.appendChild(grandChildNodes[j]);
            }
            catch(e){
              alert(e);
            }
          }
          isBold=true;
          return boldTag;
        }
        else if(spanStyle.getPropertyValue("font-style")=="italic" && spanStyle.getPropertyValue("font-weight")!="bold"){

          var italicsTag = doc.createElement('i');

            var grandChildNodes = new Array();
            for(var k=0; k < node.childNodes.length;k++){
              grandChildNodes[k] = node.childNodes[k];
            }


            for(var j=grandChildNodes.length-1; j >=0;j--)
            {
              try{
                italicsTag.appendChild(grandChildNodes[j]);
              }
              catch(e){
                alert(e);
              }
            }
          return italicsTag;
        }
    return null;

  },


  cleanInsideBlock: function(n,tag)
  {
     // call a method to strip all attributes except for span and a tag and UL as well.


    var nodeTag = tag;

    if(tag.nodeName=="P" || tag.nodeName=="LI" || tag.nodeName=="li"){
        var doc = this.getEditorWindow(n).document;

        var paragraphTag=null;
        if(tag.nodeName=="P"){
          paragraphTag = doc.createElement('P');
        }
        else if(tag.nodeName=="LI"){
          paragraphTag = doc.createElement('LI');
        }

        var newTag = null;
        if(WYSIWYG_Core.isFF){
          newTag = this.handleBoldAndItalicsInStyle(n,tag)
        }

        try{
          if(newTag!=undefined && newTag!=null){

            paragraphTag.appendChild(newTag);
            tag.parent.replaceChild(paragraphTag,nodeTag);
            tag=paragraphTag;
          }
        }
        catch(e){
          alert(e);
        }

    }

    this.stripStyleAttribute(n,tag);

    var childNodes = tag.childNodes;
    var childNodes = tag.childNodes;
      for(var i=0;i<childNodes.length;i++)
      {
         var nodeName = childNodes[i].nodeName;
         var parent = childNodes[i].parent;
        if(nodeName == "SPAN"){
          var node = childNodes[i];
            var newTag = null;
        if(WYSIWYG_Core.isFF){
          newTag = this.handleBoldAndItalicsInStyle(n,node,tag)
        }

            try{
              if(newTag!="undefined" && newTag!=null){
                tag.replaceChild(newTag,node);
              }else{
                    var node =childNodes[i];
                  var grandChildNodes = new Array();
                  var grandChildNodesSize = grandChildNodes.length;

                  for(var k=0; k < childNodes[i].childNodes.length;k++)
                  {
                      grandChildNodes[k] = childNodes[i].childNodes[k];
                  }
                  for(var j=grandChildNodes.length-1; j >=0;j--)
                  {
                    try{
                      tag.insertBefore(grandChildNodes[j],childNodes[i]);
                    }
                    catch(e){
                      alert(e);
                    }
                  }
                  tag.removeChild(node);
              }
            }
            catch(e){
              alert(e);
            }
        }
        else if (nodeName == "#text")
        {
          continue; //all ok
        }
        else if ( nodeName ==  "UL")
                {
                    this.cleanInsideUL(n,childNodes[i],parent)
                }
        else if (nodeName == "I")
        {
          this.cleanInsideStyle(n,childNodes[i], "I") //implementation pending
        }
        else if (nodeName == "STRONG")
        {
          this.cleanInsideStyle(n,childNodes[i], "STRONG") //implementation pending
        }
        else if (nodeName == "EM")
        {
          this.cleanInsideStyle(n,childNodes[i], "EM") //implementation pending
        }
        else if (nodeName == "B")
        {

          this.cleanInsideStyle(n,childNodes[i], "B")//implementation pending
        }
        else if ( nodeName == "A")
        {
           this.handleLink(n,childNodes[i])//implementation pending
        }

          else
        {
          this.cleanInsideBlock(n,childNodes[i]);

             var node =childNodes[i];
          var grandChildNodes = new Array();
          var grandChildNodesSize = grandChildNodes.length;

            for(var k=0; k < childNodes[i].childNodes.length;k++){
              grandChildNodes[k] = childNodes[i].childNodes[k];
            }
            for(var j=grandChildNodes.length-1; j >=0;j--)
            {
              try{
                tag.insertBefore(grandChildNodes[j],childNodes[i]);
              }
              catch(e){
                alert(e);
              }
            }
          tag.removeChild(node);
        }
    }
  },


  cleanInsideStyle: function(n,tag, excludeType)
  {

    // call a method to strip all attributes except for span and a tag and UL as well.
    this.stripStyleAttribute(n,tag);
    var childNodes = tag.childNodes;

    for(var i=0;i<childNodes.length;i++)
    {
      var nodeName = childNodes[i].nodeName;

      //no <b> inside <b>
      if ( nodeName == excludeType)
      {
              this.cleanInsideStyle(n,childNodes[i], excludeType);

         var node =childNodes[i];
        var grandChildNodes = new Array();
        var grandChildNodesSize = grandChildNodes.length;

          for(var k=0; k < childNodes[i].childNodes.length;k++){
            grandChildNodes[k] = childNodes[i].childNodes[k];
          }
          for(var j=grandChildNodes.length-1; j >=0;j--)
          {
            try{
              tag.insertBefore(grandChildNodes[j],childNodes[i]);
            }
            catch(e){
              alert(e);
            }
          }
        tag.removeChild(node);
      }
          if (nodeName == "STRONG" || nodeName == "EM" || nodeName ==  "B" || nodeName ==  "I")
        {
          this.cleanInsideBothStyles(n,childNodes[i])// implementation is pending
      }
          else if ( nodeName == "A")
        {
         this.handleLink(n,childNodes[i])
      }
      else  if (nodeName == "#text") {
        continue //leave it there
      }
      else {
              this.cleanInsideStyle(n,childNodes[i], excludeType);

         var node =childNodes[i];
        var grandChildNodes = new Array();
        var grandChildNodesSize = grandChildNodes.length;

          for(var k=0; k < childNodes[i].childNodes.length;k++){
            grandChildNodes[k] = childNodes[i].childNodes[k];
          }
          for(var j=grandChildNodes.length-1; j >=0;j--)
          {
            try{
              tag.insertBefore(grandChildNodes[j],childNodes[i]);
            }
            catch(e){
              alert(e);
            }
          }
        tag.removeChild(node);
      }
    }
  },



  cleanInsideBothStyles: function(n,tag, excludeType)
  {
      // call a method to strip all attributes except for span and a tag and UL as well.
        this.stripStyleAttribute(n,tag);
    var childNodes = tag.childNodes;

    for(var i=0;i<childNodes.length;i++)
    {

      var nodeName = childNodes[i].nodeName;
      if (nodeName == "STRONG" || nodeName == "EM" || nodeName ==  "B" || nodeName ==  "I")
      {
        this.cleanInsideStyle(n,childNodes[i], excludeType);

         var node =childNodes[i];
        var grandChildNodes = new Array();
        var grandChildNodesSize = grandChildNodes.length;

          for(var k=0; k < childNodes[i].childNodes.length;k++){
            grandChildNodes[k] = childNodes[i].childNodes[k];
          }
          for(var j=grandChildNodes.length-1; j >=0;j--)
          {
            try{
              tag.insertBefore(grandChildNodes[j],childNodes[i]);
            }
            catch(e){
              alert(e);
            }
          }
        tag.removeChild(node);
      }
      else if ("A")
      {
        this.handleLink(n,childNodes[i])
      }
      else  if (nodeName == "#text") {
        //leave it there
        }
          else
      {
        this.cleanInsideBoth(n,childNodes[i], excludeType);
         var node =childNodes[i];
        var grandChildNodes = new Array();
        var grandChildNodesSize = grandChildNodes.length;

          for(var k=0; k < childNodes[i].childNodes.length;k++){
            grandChildNodes[k] = childNodes[i].childNodes[k];
          }
          for(var j=grandChildNodes.length-1; j >=0;j--)
          {
            try{
              tag.insertBefore(grandChildNodes[j],childNodes[i]);
            }
            catch(e){
              alert(e);
            }
          }
        tag.removeChild(node);
      }
    }
  },



  cleanInsideUL: function(n,tag,parent)
  {
    if(WYSIWYG_Core.isFF){
      tag = this.handleIndentationOfBullet(n,tag,parent);
    }
    this.stripStyleAttribute(n,tag);
    var childNodes = tag.childNodes;
    for(var i=0;i<childNodes.length;i++)
    {
      var nodeName = childNodes[i].nodeName;
      var isEmpty = this.removeBlankNodes(childNodes[i],tag);

      if(isEmpty){
        continue;
      }

      if(nodeName == "SPAN"){
        var node = childNodes[i];
          var newTag = null;
        if(WYSIWYG_Core.isFF){
          newTag = this.handleBoldAndItalicsInStyle(n,node,tag)
        }

          try{
            if(newTag!="undefined" && newTag!=null){
              tag.replaceChild(newTag,node);
            }
            else
            {
                    var node =childNodes[i];
                  var grandChildNodes = new Array();
                  var grandChildNodesSize = grandChildNodes.length;

                  for(var k=0; k < childNodes[i].childNodes.length;k++)
                  {
                      grandChildNodes[k] = childNodes[i].childNodes[k];
                  }
                  for(var j=grandChildNodes.length-1; j >=0;j--)
                  {
                    try{
                      tag.insertBefore(grandChildNodes[j],childNodes[i]);
                    }
                    catch(e){
                      alert(e);
                    }
                  }
                  tag.removeChild(node);
              }
          }
          catch(e){
            alert(e);
          }
      }
      else if (nodeName == "STRONG" || nodeName == "EM" || nodeName == "B" || nodeName == "I" || nodeName == "A" || nodeName == "#text")
      {
        var childNode = childNodes[i];
         var doc = this.getEditorWindow(n).document;
        var liTag = doc.createElement('LI');
        try{
          tag.replaceChild(liTag,childNodes[i]);
          liTag.appendChild(childNode);
        }
        catch(e){
          alert(e);
        }


        this.cleanInsideBlock(n,liTag);
      }
      else if ( nodeName ==  "UL")
      {
        this.cleanInsideUL(n,childNodes[i],parent)
      }
      else if (nodeName ==  "LI")
      {
        this.cleanInsideBlock(n,childNodes[i]);
      }
      else {
        this.cleanInsideUL(n,childNodes[i],parent);
         var node =childNodes[i];
        var grandChildNodes = new Array();
        var grandChildNodesSize = grandChildNodes.length;

          for(var k=0; k < childNodes[i].childNodes.length;k++){
            grandChildNodes[k] = childNodes[i].childNodes[k];
          }
          for(var j=grandChildNodes.length-1; j >=0;j--)
          {
            try{
              tag.insertBefore(grandChildNodes[j],childNodes[i]);
            }
            catch(e){
              alert(e);
            }
          }
        tag.removeChild(node);
      }
    }
  },



  removeBlankNodes: function(tag,parent){

    if(tag.innerHTML==undefined || tag.innerHTML=="" || tag.innerHTML==null )
    {
        if(parent!=null && parent!="unspecified"){
            parent.removeChild(tag);
        }
        return true;
    }
    return false;
  },

  handleIndentationOfBullet: function(n,tag,parent){


    var tagStyle = tag.style;
    var node = tag;

    if(tagStyle==undefined || tagStyle==null){
      return tag;
    }

    var indentation = tagStyle.getPropertyValue("margin-left")

    if(indentation == "40px"){

      var doc = this.getEditorWindow(n).document;

        var ulTag = doc.createElement('UL');

        var ulTagInner = doc.createElement('UL');

        var grandChildNodes = new Array();

        for(var k=0; k < tag.childNodes.length;k++)
        {
          grandChildNodes[k] = tag.childNodes[k];
        }

        for(var j=0; j <grandChildNodes.length;j++)
        {
          try{
            ulTagInner.appendChild(grandChildNodes[j]);
          }
          catch(e){
            alert(e);
          }
        }

        ulTag.appendChild(ulTagInner);

        try{
            if(parent!=null && parent!="unspecified"){
             parent.replaceChild(ulTag,tag);
          }
        }
        catch(e){
          alert("Exception: "+e);
        }
        return ulTag;

    }
    else if(indentation == "80px")
    {
      var doc = this.getEditorWindow(n).document;
      var ulTag = doc.createElement('UL');
      var ulTagInner = doc.createElement('UL');
      var ulTagInner2 = doc.createElement('UL');

      var grandChildNodes = new Array();

        for(var k=0; k < tag.childNodes.length;k++)
        {
          grandChildNodes[k] = tag.childNodes[k];
        }

        for(var j=0; j <grandChildNodes.length;j++)
        {
          try{
            ulTagInner2.appendChild(grandChildNodes[j]);
          }
          catch(e){
            alert(e);
          }
        }

        ulTagInner.appendChild(ulTagInner2);
        ulTag.appendChild(ulTagInner);

        try{
            if(parent!=null && parent!="unspecified"){
                 parent.replaceChild(ulTag,tag);
          }
        }
        catch(e){
          alert(e);
        }
      return ulTag;

    }

    return node;
  },


  handleLink: function(n,tag)
  {
    //check the href
    this.stripStyleAttribute(n,tag);
    this.stripAllStyling(n,tag)
  },

  stripAllStyling: function(n,tag)
  {

  if(tag==undefined || tag==null){
    return;
  }
   var childNodes = tag.childNodes;
    for(var i=0;i<childNodes.length;i++)
    {
      var nodeName = childNodes[i].nodeName;
      if (nodeName == "#text") {
         continue; //OK
      }
      else {
        this.stripAllStyling(childNodes[i]);

         var node =childNodes[i];
        var grandChildNodes = new Array();
        var grandChildNodesSize = grandChildNodes.length;

          for(var k=0; k < childNodes[i].childNodes.length;k++){
            grandChildNodes[k] = childNodes[i].childNodes[k];
          }
          for(var j=grandChildNodes.length-1; j >=0;j--)
          {
            try{
              tag.insertBefore(grandChildNodes[j],childNodes[i]);
            }
            catch(e){
              alert(e);
            }
          }
        tag.removeChild(node);
      }
    }
  },


  stripStyleAttribute: function(n,tag){
    if(tag.nodeName != "#text"){
      tag.removeAttribute("style");
    }
  },




  /**
   * Removes the bullet formatting from the current selection
   * to make it a header.
   *
   * @param {String} n The editor identifier (the textarea's ID)
   */
  removeBulletsForHeaders: function(n) {
      // get selection and range
    var sel = this.getSelection(n);
    var range = this.getRange(sel);
    // the current tag of range
    var tag = this.getTag(range);

    if(tag == null) {
      return;
    }

    var oneIndent = false;

    if(tag.parentNode.parentNode.nodeName!="UL"){
      oneIndent = true;
    }


    /*
     * This is to handle when a bullet is also bold,italics or a hyperlink. We are handling three hirerachy
     * levels for example we have text which is bold + italics and its also a hyperlink.
     */
    if(tag.nodeName != "#document-fragment" && tag.parentNode.nodeName=="LI"){
      var parent = tag.parentNode;
      tag = parent;
    }
    else if( tag.parentNode.parentNode.nodeName=="LI" ){
      var parent = tag.parentNode.parentNode;
      tag = parent;
    }
    else if( tag.parentNode.parentNode.parentNode != null && tag.parentNode.parentNode.parentNode.nodeName=="LI" ){
      var parent = tag.parentNode.parentNode.parentNode;
      tag = parent;
    }



    /*
     * Below algorithm removes the bullets format. Its a while loop for
     * more than 1 indents in bullet format.
     */
    while(true){
      var isBullet= false;
      //if((tag.nodeName != "UL" && tag.nodeName != "LI") || ((tag.parentNode != null && tag.parentNode.nodeName != "LI") && (tag.parentNode != null && tag.parentNode.nodeName != "UL"))) { return; }
      if(tag.nodeName != "UL" && tag.nodeName != "LI" && tag.nodeName != "#document-fragment") {
        return;
      }
      if(tag.nodeName == "UL" || tag.nodeName == "LI"){
         WYSIWYG_Core.execCommand(n, "InsertUnorderedList","");
         isBullet=true;
      }
      if(oneIndent  && tag.nodeName == "#document-fragment"){
         return;
      }
      if(!isBullet || WYSIWYG_Core.isFF){
        this.removeNode(n,tag);
      }
        if(tag.parentNode!=null){
          if(tag.parentNode.nodeName!="UL"){
            var parent = tag.parentNode;
          tag = parent;
        }
      }
      else{
        break;
      }
    }
    return;
  },



  /*
   * This is for getting the current position of Cursor.
   * Works only for IE.
   */
  doGetCaretPosition: function(n) {
    var CaretPos = 0;  // IE Support
    var doc = this.getEditorWindow(n).document;
    var str = doc.body.innerHTML;
    // get selection and range
    var sel = this.getSelection(n);
    var range = this.getRange(sel);
    var editor = this.getEditor(n);

    if (document.selection) {

      editor.focus ();
      var Sel = sel.createRange ();
      Sel.moveStart ('character', -str.length);
      CaretPos = Sel.text.length;
    }
    this.cursorPosition = CaretPos;
    return (CaretPos);
  },


  /*
   * This is for setting the current position of Cursor.
   * Works only for IE.
   */
  setCaretPosition: function(n){
    var doc = this.getEditorWindow(n).document;
    var str = doc.body.innerHTML;
    // get selection and range
    var sel = this.getSelection(n);
    var range = this.getRange(sel);
    var editor = this.getEditorWindow(n);
    if (doc.body.createTextRange) {
      var range = doc.body.createTextRange();
      range.collapse(true);
      range.moveEnd('character', this.cursorPosition);
      range.moveStart('character', this.cursorPosition);
      range.select();
    }
  },



  // This will insert HTML at current cursor position
  insertAtCursor: function(n,text, replaceContents) {
        if(replaceContents==null){replaceContents=false;}
        if(!replaceContents){//collapse selection:
           var sel = this.getSelection(n);
           sel.collapseToStart()
        }
        WYSIWYG_Core.execCommand(n,'insertHTML',text);
  },


  // Reset cursor position
  resetCaret: function(n){
        var iframe=this.getEditorWindow(n);
        var referenceNode = iframe.document.getElementById("caret");
        var range;
        if(referenceNode){
           var sel=this.getSelection(n);

           if(sel.focusNode){//firefox:
               range=sel.getRangeAt(0);
           }else{//chrome:
               range=iframe.document.createRange();
           }
        range.selectNode(referenceNode);
       range.deleteContents();
       }

  },






  /**
   * Removes the current node of the selection if its a header. Aso get
   * count of existing indents of bullet if there is any.
   *
   * @param {String} n The editor identifier (the textarea's ID)
   */
  removeNodeForBullets: function(n) {
    // get selection and range
    var sel = this.getSelection(n);
    var range = this.getRange(sel);
    // the current tag of range

    var tag = this.getTag(range);
    var parent = null;

    if(tag!=null){
      parent = tag.parentNode;
    }

    if(tag == null || tag.parentNode == null) { return 0; }

    //NOTE: #document-fragment happens only in IE which repersents a text.


    /*
     * This is to handle when header is also italics
     */
    if(tag.nodeName != "#document-fragment" && (tag.parentNode.nodeName=="H1" || tag.parentNode.nodeName=="H2" || tag.parentNode.nodeName=="H3")){
      var _parent = tag.parentNode;
      tag = _parent;
    }
    else if( tag.parentNode.parentNode.nodeName=="H1" || tag.parentNode.parentNode.nodeName=="H2" || tag.parentNode.parentNode.nodeName=="H3" ){
      var _parent = tag.parentNode.parentNode;
      tag = _parent;
    }

    /*
     * This is to handle when a bullet is also bold,italics or a hyperlink. We are handling three hirerachy
     * levels for example we have text which is bold + italics and its also a hyperlink.
     */
    if(tag.nodeName != "#document-fragment" && (tag.parentNode.nodeName=="LI")){
      var _parent = tag.parentNode;
      tag = _parent;
    }
    else if( tag.parentNode.parentNode!=null && tag.parentNode.parentNode.nodeName=="LI" ){
      var _parent = tag.parentNode.parentNode;
      tag = _parent;
    }
    else if( tag.parentNode.parentNode.parentNode!=null && tag.parentNode.parentNode.parentNode.nodeName=="LI" ){
      var _parent = tag.parentNode.parentNode.parentNode;
      tag = _parent;
    }

    // reassign the parent becuase there is a possibilty that tag object has been changed.
    if(tag!=null){
      parent = tag.parentNode;
    }


    // In case tag is not a header or a bullet we don't care we don't need to remove or modify any format
    // go ahead with whatever it is.
    if(!(tag.nodeName == "BR" && parent.nodeName == "LI") && tag.nodeName != "H1" && tag.nodeName != "H2" && tag.nodeName != "H3" && tag.nodeName != "UL" && tag.nodeName != "LI") { return 0; }


    if(tag.nodeName == "BR"){
      parent = tag.parentNode.parentNode;
      tag = tag.parentNode;
      if(parent==null){
        return 0;
      }

    }


    /*
     * Below algorithm removes the header formatting when a header needs to be a bullet.
     */
    if(tag.nodeName == "H1" || tag.nodeName == "H2" || tag.nodeName == "H3"){

      //get parent of parent node.
      parent = tag.parentNode.parentNode;

      //array of child elements
      var childNodes = new Array();

      //get parent
      parent = tag.parentNode;

      //get document object
      var doc = this.getEditorWindow(n).document;

      //create a paragraph element
      var paragraphTag = doc.createElement('p');

      //copy all child elements of tag into childNodes array
      for(var i=0; i < tag.childNodes.length;i++){
        childNodes[i] = tag.childNodes[i];
      }

      // Append childNodes array to paragraph element paragraghTag
      for(var i=0; i < childNodes.length;i++){
        paragraphTag.appendChild(childNodes[i]);
      }

      //replace header element with paragraph element
      parent.replaceChild(paragraphTag,tag);

      //select that node as we have to make it bullet now. so focus must be on that tag
      if(WYSIWYG_Core.isFF) {
        range.selectNode(paragraphTag);
      }
      else{
        range.select();
      }

      if(parent==null){
        return 0;
      }
    }

    var countOfExistingIndents =0;

    var parentnotNull = false;

    /*
        * Below code counts for the existing bullet indents
     * this count will be returned back and bullets will be processed accordingly
     */
    if(parent.nodeName == "UL") {
      countOfExistingIndents++;
    }
    if(parent.parentNode!=null  && parent.parentNode.nodeName == "UL") {
      countOfExistingIndents++;
      parentnotNull=true;
    }
    if(parentnotNull && parent.parentNode.parentNode!=null  && parent.parentNode.parentNode.nodeName == "UL") {
      countOfExistingIndents++;
    }
    return countOfExistingIndents;
  },


  getHeaderName: function(n) {
    // get selection and range
    var sel = this.getSelection(n);
    var range = this.getRange(sel);
    // the current tag of range

    var tag = this.getTag(range);
    var parent = tag.parentNode;

    if(tag == null || parent == null) { return 0; }

    if(!(tag.nodeName == "BR" && parent.nodeName == "LI") && tag.nodeName != "H1" && tag.nodeName != "H2" && tag.nodeName != "H3" && tag.nodeName != "UL" && tag.nodeName != "LI") { return 0; }

    if(tag.nodeName == "H1" || tag.nodeName == "H2" || tag.nodeName == "H3"){
      parent = tag.parentNode.parentNode;
      tag = tag.parentNode;
             return tag.nodeName;
    }
  },
  /**
   * Get the selection of the given editor
   *
   * @param {String} n The editor identifier (the textarea's ID)
   */
  getSelection: function(n) {
    var ifrm = this.getEditorWindow(n);
    var doc = ifrm.document;
    var sel = null;
    if(ifrm.getSelection){
      sel = ifrm.getSelection();
    }
    else if (doc.getSelection) {
      sel = doc.getSelection();
    }
    else if (doc.selection) {
      sel = doc.selection;
    }
    return sel;
  },

  /**
   * Updates the status bar with the current node tree
   *
   * @param {String} n The editor identifier (the textarea's ID)
   */
  updateStatusBar: function(n) {
    // get the node structure
    var nodeTree = this.getNodeTree(n);
    if(nodeTree == null) { return; }
    // format the output
    var outputTree = "";
    var max = nodeTree.length - 1;
    for(var i=max;i>=0;i--) {
      if(nodeTree[i].nodeName != "HTML" && nodeTree[i].nodeName != "BODY") {
        outputTree += '<a class="wysiwyg-statusbar" href="javascript:WYSIWYG.selectNode(\'' + n + '\',' + i + ');">' + nodeTree[i].nodeName + '</a>';
      }
      else {
        outputTree += nodeTree[i].nodeName;
      }
      if(i > 0) { outputTree += " > "; }
    }

    // update the status bar
    var statusbar = $("wysiwyg_statusbar_" + n);
    if(statusbar){
      statusbar.innerHTML = outputTree;
    }
  },

  /**
   * Execute a command on the editor document
   *
   * @param {String} command The execCommand (e.g. Bold)
   * @param {String} n The editor identifier
   * @param {String} value The value when applicable
   */
  execCommand: function(n, cmd, value) {

  //  this.init(n);
    if(WYSIWYG_Core.isFF && cmd != "CreateLink" && cmd != "Italic"){
      //this.insertAtCursor(n,'<a href="" id="caret" />', 0); //change 0 to 1 if you want the user's selection to be replaced by the img
      //this.saveSelection();
    }
    if( !WYSIWYG_Core.isFF && cmd != "CreateLink" && cmd !="Bold" && cmd != "Italic" ){
      //this.doGetCaretPosition(n);
    }


    // When user clicks toolbar button make sure it always targets its respective WYSIWYG
    this.getEditorWindow(n).focus();

    // When in Text Mode these execCommands are enabled
    var textModeCommands = new Array("ViewText", "Print");

      // Check if in Text mode and a disabled command execute
    var cmdValid = false;
    for (var i = 0; i < textModeCommands.length; i++) {
      if (textModeCommands[i] == cmd) {
        cmdValid = true;
      }
    }
    if(this.viewTextMode[n] && !cmdValid) {
      alert("You are in TEXT Mode. This feature has been disabled.");
        return false;
    }

    // rbg to hex convertion implementation dependents on browser
    var toHexColor = WYSIWYG_Core.isMSIE ? WYSIWYG_Core._dec_to_rgb : WYSIWYG_Core.toHexColor;

    // popup screen positions
    var popupPosition = {left: parseInt(window.screen.availWidth / 3), top: parseInt(window.screen.availHeight / 3)};

    // Check the insert image popup implementation
    var imagePopupFile = this.config[n].PopupsDir + 'insert_image.html';
    var imagePopupWidth = 400;
    var imagePopupHeight = 210;
    if(typeof this.config[n].ImagePopupFile != "undefined" && this.config[n].ImagePopupFile != "") {
      imagePopupFile = this.config[n].ImagePopupFile;
    }
    if(typeof this.config[n].ImagePopupWidth && this.config[n].ImagePopupWidth > 0) {
      imagePopupWidth = this.config[n].ImagePopupWidth;
    }
    if(typeof this.config[n].ImagePopupHeight && this.config[n].ImagePopupHeight > 0) {
      imagePopupHeight = this.config[n].ImagePopupHeight;
    }
    // switch which action have to do
    switch(cmd) {
      case "Maximize":
        this.maximize(n);
      break;
      case "Normal":
        this.removeNode(n);
        break;
      case "H1":
        this.removeBulletsForHeaders(n);
        WYSIWYG_Core.execCommand(n, "FormatBlock", "<H1>");
        this.parseAndremoveUnwanted(n);
        break;

      case "H2":
        this.removeBulletsForHeaders(n);
        WYSIWYG_Core.execCommand(n, "FormatBlock", "<H2>");
        this.parseAndremoveUnwanted(n);
        break;

      case "H3":
        this.removeBulletsForHeaders(n);
        WYSIWYG_Core.execCommand(n, "FormatBlock", "<H3>");
        this.parseAndremoveUnwanted(n);
        break;

      case "Bullet 1":

      var count = this.removeNodeForBullets(n);

        if(count!=0){
          if(count == 1 ){
            WYSIWYG_Core.execCommand(n, "InsertUnorderedList",'');
          }
          else if(count == 2 ){
            WYSIWYG_Core.execCommand(n, "Outdent",value);
          }
          else if(count == 3 ){
            WYSIWYG_Core.execCommand(n, "Outdent",value);
            WYSIWYG_Core.execCommand(n, "Outdent",value);
          }

         }
         else{
          WYSIWYG_Core.execCommand(n, "InsertUnorderedList",'');
         }
        this.parseAndremoveUnwanted(n);
        break;
      case "Bullet 2":
             var count = this.removeNodeForBullets(n);
             if(count!=0){
              if(count == 1 ){
                WYSIWYG_Core.execCommand(n, "Indent",value);
              }
              else if(count ==2){
                WYSIWYG_Core.execCommand(n, "InsertUnorderedList",value);
              }
              else if(count == 3 ){
                WYSIWYG_Core.execCommand(n, "Outdent",value);
              }

             }
             else{
              WYSIWYG_Core.execCommand(n, "InsertUnorderedList",value);
              WYSIWYG_Core.execCommand(n, "Indent",value);
             }
             this.parseAndremoveUnwanted(n);
          break;
      case "Bullet 3":
            var count = this.removeNodeForBullets(n);

                if(count!=0){
              if(count ==  1){
                WYSIWYG_Core.execCommand(n, "Indent",value);
                WYSIWYG_Core.execCommand(n, "Indent",value);
              }
              else if(count == 2 ){
                WYSIWYG_Core.execCommand(n, "Indent",value);
              }

              else if(count == 3 ){
              WYSIWYG_Core.execCommand(n, "InsertUnorderedList",value);
            }

             }
                       else{
            WYSIWYG_Core.execCommand(n, "InsertUnorderedList",value);
            WYSIWYG_Core.execCommand(n, "Indent",value);
            WYSIWYG_Core.execCommand(n, "Indent",value);
                       }
            this.parseAndremoveUnwanted(n);
        break;

      case "FormatBlock":
        if(value=="Normal"){
          this.removeNode(n);
        }
        else{
          this.removeBulletsForHeaders(n);
          WYSIWYG_Core.execCommand(n, cmd, "<" + value + ">");
        }
        this.parseAndremoveUnwanted(n);
      break;


      // ForeColor and
      case "ForeColor":
        var rgb = this.getEditorWindow(n).document.queryCommandValue(cmd);
            var currentColor = rgb != '' ? toHexColor(this.getEditorWindow(n).document.queryCommandValue(cmd)) : "000000";
          window.open(this.config[n].PopupsDir + 'select_color.html?color=' + currentColor + '&command=' + cmd + '&wysiwyg=' + n, 'popup', 'location=0,status=0,scrollbars=0,width=210,height=165,top=' + popupPosition.top + ',left=' + popupPosition.left).focus();
      break;

      // BackColor
      case "BackColor":
        var currentColor = toHexColor(this.getEditorWindow(n).document.queryCommandValue(cmd));
          window.open(this.config[n].PopupsDir + 'select_color.html?color=' + currentColor + '&command=' + cmd + '&wysiwyg=' + n, 'popup', 'location=0,status=0,scrollbars=0,width=210,height=165,top=' + popupPosition.top + ',left=' + popupPosition.left).focus();
      break;

      // InsertImage
      case "InsertImage":
        window.open(imagePopupFile + '?wysiwyg=' + n, 'popup', 'location=0,status=0,scrollbars=0,resizable=0,width=' + imagePopupWidth + ',height=' + imagePopupHeight + ',top=' + popupPosition.top + ',left=' + popupPosition.left).focus();
      break;

      // Remove Image
      case "RemoveImage":
        this.removeImage(n);
      break;

      // Remove Link
      case "RemoveLink":
        this.removeLink(n);
      break;

      // Remove a Node
      case "RemoveNode":
        this.removeNode(n);
      break;

      // Create Link
      case "CreateLink":
        var sel = this.getSelection(n);
        if(sel==null || sel==''){
          alert('Select a text in the editor for hyperlink.');
        }
        else{
          window.open(this.config[n].PopupsDir + 'insert_hyperlink.jsp?wysiwyg=' + n, 'popup', 'location=0,status=0,scrollbars=0,resizable=0,width=600,height=400,top=' + popupPosition.top + ',left=' + popupPosition.left).focus();
        //  loadLink();
          //YAHOO.example.container.dialog1.show();
        }
        this.parseAndremoveUnwanted(n);
      break;

      // InsertTable
      case "InsertTable":
        window.open(this.config[n].PopupsDir + 'create_table.html?wysiwyg=' + n, 'popup', 'location=0,status=0,scrollbars=0,resizable=0,width=500,height=260,top=' + popupPosition.top + ',left=' + popupPosition.left).focus();
      break;

      // InsertTable
      case "inserthorizontalrule":
        WYSIWYG_Core.execCommand(n, cmd, null);
      break;

      // ViewSource
      case "ViewSource":
        this.viewSource(n);
      break;

      // ViewText
      case "ViewText":
        this.viewText(n);
      break;

      // Help
      case "Help":
        window.open(this.config[n].PopupsDir + 'about.html?wysiwyg=' + n, 'popup', 'location=0,status=0,scrollbars=0,resizable=0,width=400,height=350,top=' + popupPosition.top + ',left=' + popupPosition.left).focus();
      break;

      // Strip any HTML added by word
      case "RemoveFormat":
        //this.removeFormat(n);
        this.pasteStuff(n);
      break;

      // Preview thx to Korvo
      case "Preview":
        window.open(this.config[n].PopupsDir + 'preview.html?wysiwyg=' + n,'popup', 'location=0,status=0,scrollbars=1,resizable=1,width=' + this.config[n].PreviewWidth + ',height=' + this.config[n].PreviewHeight + ',top=' + popupPosition.top + ',left=' + popupPosition.left).focus();
      break;

      // Print
      case "Print":
        this.print(n);
      break;

      // Save
      case "Save":
        this.parseAndremoveUnwanted(n)
        this.removeFormat(n);
          WYSIWYG.updateTextArea(n);
          var form = WYSIWYG_Core.findParentNode("FORM", this.getEditor(n));

          if(form == null) {
            alert("Can not submit the content, because no form element found.");
            return true;
          }
          //form.submit();
      break;

      // Return
      case "Return":
         location.replace(this.config[n].Opener);
      break;

      default:
        WYSIWYG_Core.execCommand(n, cmd, value);

    }
    if(!WYSIWYG_Core.isFF && cmd != "CreateLink" && cmd !="Bold" && cmd != "Italic" && cmd != "ViewSource" && cmd != "ViewText"){
      //this.removeFormat(n);
    }
    // hide node the font + font size selection
    this.closeDropDowns(n);

    //after the save:
    if(WYSIWYG_Core.isFF){
    //  var ctrl = this.getEditor(n);
    //  ctrl.focus();
    //  alert(ctrl.firstChild.setSelectionRange);
    //  this.getEditor(n).firstChild.setSelectionRange(pos,pos);

//      this.resetCaret(n);
  //    restoreSelection(n);
    }
    if(!WYSIWYG_Core.isFF && cmd != "CreateLink" && cmd !="Bold" && cmd != "Italic"){
      //this.setCaretPosition(n);
    }

    return true;
  },


    init:  function(n) {

        var win = this.getEditorWindow(n);
        this.selectionUtil = createSelectionUtil(win);

        if (this.selectionUtil.saveRestoreSupported) {
            saveSelection = function() {
                if (this.savedSelection) {
                    this.selectionUtil.removeMarkers(this.savedSelection);
                }
                this.savedSelection = this.selectionUtil.saveSelection();
           //     document.getElementById("restoreButton").disabled = false;
            };

            restoreSelection = function() {
                if (this.savedSelection) {
                    this.selectionUtil.restoreSelection(this.savedSelection);
                    this.savedSelection = null;
             //       document.getElementById("restoreButton").disabled = true;
                    document.getElementById("editable").focus();
                }
            };
        }
    },

    saveSelection:  function() {
        if (this.savedSelection) {
            this.selectionUtil.removeMarkers(this.savedSelection);
        }

        this.savedSelection = this.selectionUtil.saveSelection();
   //     document.getElementById("restoreButton").disabled = false;
    },
    restoreSelection: function(n) {
        if (this.savedSelection) {
            this.selectionUtil.restoreSelection(this.savedSelection);
            this.savedSelection = null;
     //       document.getElementById("restoreButton").disabled = true;
            this.getEditor(n).focus();
        }
    },
  /**
   * Maximize the editor instance
   *
   * @param {String} n The editor identifier
   */
  maximize: function(n) {

    var divElm = this.getEditorDiv(n);
    var tableElm = this.getEditorTable(n);
    var editor = this.getEditor(n);
    var setting = this.config[n];
    var size = WYSIWYG_Core.windowSize();
    size.width -= 5;
    if(this.maximized[n]) {
      WYSIWYG_Core.setAttribute(divElm, "style", "position:static;z-index:9998;top:0px;left:0px;width:" + setting.Width + ";height:100%;");
      WYSIWYG_Core.setAttribute(tableElm, "style", "width:" + setting.Width + ";height:" + setting.Height + ";");
      WYSIWYG_Core.setAttribute(editor, "style", "width:100%;height:" + setting.Height + ";");
      this.maximized[n] = false;
    }
    else {
      WYSIWYG_Core.setAttribute(divElm, "style", "position:absolute;z-index:9998;top:0px;left:0px;width:" + size.width + "px;height:" + size.height + "px;");
      WYSIWYG_Core.setAttribute(tableElm, "style", "width:100%;height:100%;");
      WYSIWYG_Core.setAttribute(editor, "style", "width:100%;height:100%;");
      this.maximized[n] = true;
    }

  },

  /**
   * Insert HTML into WYSIWYG in rich text
   *
   * @param {String} html The HTML being inserted (e.g. <b>hello</b>)
   * @param {String} n The editor identifier
   */
  insertHTML: function(html, n) {
    if (WYSIWYG_Core.isMSIE) {
      var tag =this.getTag( this.getEditorWindow(n).document.selection.createRange());
      tag.innerHTML = html;
    }
    else {
      var span = this.getEditorWindow(n).document.createElement("span");
      span.innerHTML = html;
      this.insertNodeAtSelection(span, n);
    }
  },

  /* ---------------------------------------------------------------------- *\
    Function    : insertNodeAtSelection()
    Description : insert HTML into WYSIWYG in rich text (mozilla)
    Usage       : WYSIWYG.insertNodeAtSelection(insertNode, n)
    Arguments   : insertNode - The HTML being inserted (must be innerHTML inserted within a div element)
                  n          - The editor identifier that the HTML will be inserted into (the textarea's ID)
  \* ---------------------------------------------------------------------- */
  insertNodeAtSelection: function(insertNode, n) {

    // get editor document
    var doc = this.getEditorWindow(n).document;
    // get current selection
    var sel = this.getSelection(n);

    // get the first range of the selection
    // (there's almost always only one range)
    var range = sel.getRangeAt(0);

    // deselect everything
    sel.removeAllRanges();

    // remove content of current selection from document
    range.deleteContents();

    // get location of current selection
    var container = range.startContainer;
    var pos = range.startOffset;

    // make a new range for the new selection
    range = doc.createRange();

    if (container.nodeType==3 && insertNode.nodeType==3) {
      // if we insert text in a textnode, do optimized insertion
      container.insertData(pos, insertNode.data);
      // put cursor after inserted text
      range.setEnd(container, pos+insertNode.length);
      range.setStart(container, pos+insertNode.length);
    }
    else {

      var afterNode;
      var beforeNode;
      if (container.nodeType==3) {
        // when inserting into a textnode
        // we create 2 new textnodes
        // and put the insertNode in between
        var textNode = container;
        container = textNode.parentNode;
        var text = textNode.nodeValue;

        // text before the split
        var textBefore = text.substr(0,pos);
        // text after the split
        var textAfter = text.substr(pos);

        beforeNode = document.createTextNode(textBefore);
        afterNode = document.createTextNode(textAfter);

        // insert the 3 new nodes before the old one
        container.insertBefore(afterNode, textNode);
        container.insertBefore(insertNode, afterNode);
        container.insertBefore(beforeNode, insertNode);

        // remove the old node
        container.removeChild(textNode);
      }
      else {
        // else simply insert the node
        afterNode = container.childNodes[pos];
        container.insertBefore(insertNode, afterNode);
      }

      try {
        range.setEnd(afterNode, 0);
        range.setStart(afterNode, 0);
      }
      catch(e) {
        //alert(e);
      }
    }

    sel.addRange(range);
  },

  /**
   * Prints the content of the WYSIWYG editor area
   *
   * @param {String} n The editor identifier (textarea ID)
   */
  print: function(n) {
    if(document.all && navigator.appVersion.substring(22,23)==4) {
      var doc = this.getEditorWindow(n).document;
      doc.focus();
      var OLECMDID_PRINT = 6;
      var OLECMDEXECOPT_DONTPROMPTUSER = 2;
      var OLECMDEXECOPT_PROMPTUSER = 1;
      var WebBrowser = '<object id="WebBrowser1" width="0" height="0" classid="CLSID:8856F961-340A-11D0-A96B-00C04FD705A2"></object>';
      doc.body.insertAdjacentHTML('beforeEnd',WebBrowser);
      WebBrowser.ExecWB(OLECMDID_PRINT, OLECMDEXECOPT_DONTPROMPTUSER);
      WebBrowser.outerHTML = '';
    } else {
      this.getEditorWindow(n).print();
    }
  },

  /**
   * Writes the content of an drop down
   *
   * @param {String} n The editor identifier (textarea ID)
   * @param {String} id Drop down identifier
   * @return {String} Drop down HTML
   */
  writeDropDown: function(n, id) {

    var dropdown = this.config[n].DropDowns[id];
    var toolbarObj = this.ToolbarList[dropdown.id];
    var image = this.config[n].ImagesDir  + toolbarObj[2];
    var imageOn  = this.config[n].ImagesDir + toolbarObj[3];
    dropdown.elements.sort();

    var output = "";
    output += '<table border="0" cellpadding="0" cellspacing="0"><tr>';
    output += '<td onMouseOver="$(\'img_' + dropdown.id + '_' + n + '\').src=\'' + imageOn + '\';" onMouseOut="$(\'img_' + dropdown.id + '_' + n + '\').src=\'' + image + '\';">';
    output += '<img src="' + image + '" id="img_' + dropdown.id + '_' + n + '" height="20" onClick="WYSIWYG.openDropDown(\'' + n + '\',\'' + dropdown.id + '\');" unselectable="on" border="0"><br>';
    output += '<span id="elm_' + dropdown.id + '_' + n + '" class="dropdown" style="width: 145px;display:none;">';
    for (var i = 0; i < dropdown.elements.length;i++) {
      if (dropdown.elements[i]) {
        var value = dropdown.elements[i];
        var label = dropdown.label.replace(/{value}/gi, value);
        // output
          output += '<button type="button" onClick="WYSIWYG.execCommand(\'' + n + '\',\'' + dropdown.command + '\',\'' + value + '\')\;" onMouseOver="this.className=\'mouseOver\'" onMouseOut="this.className=\'mouseOut\'" class="mouseOut" style="width: 120px;">';
          output += '<table cellpadding="0" cellspacing="0" border="0"><tr>';
          output += '<td align="left">' + label + '</td>';
          output += '</tr></table></button><br>';
        }
      }
      output += '</span></td></tr></table>';

    return output;
  },

  /**
   * Close all drop downs. You can define a exclude dropdown id
   *
   * @param {String} n The editor identifier (textarea ID)
     * @param {String} exid Excluded drop down identifier
   */
  closeDropDowns: function(n, exid) {
    if(typeof(exid) == "undefined") exid = "";
    var dropdowns = this.config[n].DropDowns;
    for(var id in dropdowns) {
      var dropdown = dropdowns[id];
      if(dropdown.id != exid) {
        var divId = "elm_" + dropdown.id + "_" + n;
        if($(divId)) $(divId).style.display = 'none';
      }
    }
  },

  /**
   * Open a defined drop down
   *
     * @param {String} n The editor identifier (textarea ID)
   * @param {String} id Drop down identifier
   */
  openDropDown: function(n, id) {
    var divId = "elm_" + id + "_" + n;
    if($(divId).style.display == "none") {
      $(divId).style.display = "block";
    }
    else {
      $(divId).style.display = "none";
    }
    $(divId).style.position = "absolute";
    this.closeDropDowns(n, id);
  },

  /**
   * Shows the HTML source code generated by the WYSIWYG editor
   *
   * @param {String} n The editor identifier (textarea ID)
   */
  viewSource: function(n) {

    // document
    var doc = this.getEditorWindow(n).document;

    // Enable table highlighting
    WYSIWYG_Table.disableHighlighting(n);

    // View Source for IE
    if (WYSIWYG_Core.isMSIE) {
      var iHTML = doc.body.innerHTML;
      // strip off the absolute urls
      //iHTML = this.stripURLPath(n, iHTML);
      // replace all decimal color strings with hex decimal color strings
      iHTML = WYSIWYG_Core.replaceRGBWithHexColor(iHTML);
      doc.body.innerText = iHTML;
    }
      // View Source for Mozilla/Netscape
      else {
        // replace all decimal color strings with hex decimal color strings
      var html = WYSIWYG_Core.replaceRGBWithHexColor(doc.body.innerHTML);
        html = document.createTextNode(html);
        doc.body.innerHTML = "";
        doc.body.appendChild(html);
      }

    // Hide the HTML Mode button and show the Text Mode button
    // Validate if Elements are present
    if($('HTMLMode' + n)) {
        $('HTMLMode' + n).style.display = 'none';
    }
      if($('textMode' + n)) {
        $('textMode' + n).style.display = 'block';
    }

    // set the font values for displaying HTML source
    doc.body.style.fontSize = "12px";
    doc.body.style.fontFamily = "Courier New";

      this.viewTextMode[n] = true;
  },

  /**
   * Shows the HTML source code generated by the WYSIWYG editor
   *
   * @param {String} n The editor identifier (textarea ID)
   */
  viewText: function(n) {

    // get document
    var doc = this.getEditorWindow(n).document;

    // View Text for IE
    if (WYSIWYG_Core.isMSIE) {
        var iText = doc.body.innerText;
        // strip off the absolute urls
      //iText = this.stripURLPath(n, iText);
      // replace all decimal color strings with hex decimal color strings
      iText = WYSIWYG_Core.replaceRGBWithHexColor(iText);
        doc.body.innerHTML = iText;
    }

    // View Text for Mozilla/Netscape
      else {
        var html = doc.body.ownerDocument.createRange();
        html.selectNodeContents(doc.body);
        // replace all decimal color strings with hex decimal color strings
      html = WYSIWYG_Core.replaceRGBWithHexColor(html.toString());
        doc.body.innerHTML = html;
    }

    // Enable table highlighting
    WYSIWYG_Table.refreshHighlighting(n);

    // Hide the Text Mode button and show the HTML Mode button
    // Validate if Elements are present
    if($('textMode' + n)) {
      $('textMode' + n).style.display = 'none';
    }
    if($('HTMLMode' + n)) {
      $('HTMLMode' + n).style.display = 'block';
    }

    // reset the font values (changed)
    WYSIWYG_Core.setAttribute(doc.body, "style", this.config[n].DefaultStyle);

    this.viewTextMode[n] = false;
  },

  /* ---------------------------------------------------------------------- *\
    Function    : stripURLPath()
    Description : Strips off the defined image and the anchor urls of the given content.
            It also can strip the document URL automatically if you define auto.
    Usage       : WYSIWYG.stripURLPath(content)
    Arguments   : content  - Content on which the stripping applies
  \* ---------------------------------------------------------------------- */
  stripURLPath: function(n, content, exact) {

    // parameter exact is optional
    if(typeof exact == "undefined") {
      exact = true;
    }

    var stripImgageUrl = null;
    var stripAnchorUrl = null;

    // add url to strip of anchors to array
    if(this.config[n].AnchorPathToStrip == "auto") {
      stripAnchorUrl = WYSIWYG_Core.getDocumentUrl(document);
    }
    else if(this.config[n].AnchorPathToStrip != "") {
      stripAnchorUrl = this.config[n].AnchorPathToStrip;
    }

    // add strip url of images to array
    if(this.config[n].ImagePathToStrip == "auto") {
      stripImgageUrl = WYSIWYG_Core.getDocumentUrl(document);
    }
    else if(this.config[n].ImagePathToStrip != "") {
      stripImgageUrl = this.config[n].ImagePathToStrip;
    }

    var url;
    var regex;
    var result;
    // strip url of image path
    if(stripImgageUrl) {
      // escape reserved characters to be a valid regex
      url = WYSIWYG_Core.stringToRegex(WYSIWYG_Core.getDocumentPathOfUrl(stripImgageUrl));

      // exact replacing of url. regex: src="<url>"
      if(exact) {
        regex = eval("/(src=\")(" + url + ")([^\"]*)/gi");
        content = content.replace(regex, "$1$3");
      }
      // not exect replacing of url. regex: <url>
      else {
        regex = eval("/(" + url + ")(.+)/gi");
        content = content.replace(regex, "$2");
      }

      // strip absolute urls without a heading slash ("images/print.gif")
      result = WYSIWYG_Core.getDocumentPathOfUrl(stripImgageUrl).match(/.+[\/]{2,3}[^\/]*/,"");
      if(result) {
        url = WYSIWYG_Core.stringToRegex(result[0]);

        // exact replacing of url. regex: src="<url>"
        if(exact) {
          regex = eval("/(src=\")(" + url + ")([^\"]*)/gi");
          content = content.replace(regex, "$1$3");
        }
        // not exect replacing of url. regex: <url>
        else {
          regex = eval("/(" + url + ")(.+)/gi");
          content = content.replace(regex, "$2");
        }
      }
    }

    // strip url of image path
    if(stripAnchorUrl) {
      // escape reserved characters to be a valid regex
      url = WYSIWYG_Core.stringToRegex(WYSIWYG_Core.getDocumentPathOfUrl(stripAnchorUrl));

      // strip absolute urls with a heading slash ("/product/index.html")
      // exact replacing of url. regex: src="<url>"
      if(exact) {
        regex = eval("/(href=\")(" + url + ")([^\"]*)/gi");
        content = content.replace(regex, "$1$3");
      }
      // not exect replacing of url. regex: <url>
      else {
        regex = eval("/(" + url + ")(.+)/gi");
        content = content.replace(regex, "$2");
      }

      // strip absolute urls without a heading slash ("product/index.html")
      result = WYSIWYG_Core.getDocumentPathOfUrl(stripAnchorUrl).match(/.+[\/]{2,3}[^\/]*/,"");
      if(result) {
        url = WYSIWYG_Core.stringToRegex(result[0]);
        // exact replacing of url. regex: src="<url>"
        if(exact) {
          regex = eval("/(href=\")(" + url + ")([^\"]*)/gi");
          content = content.replace(regex, "$1$3");
        }
        // not exect replacing of url. regex: <url>
        else {
          regex = eval("/(" + url + ")(.+)/gi");
          content = content.replace(regex, "$2");
        }

      }

      // stip off anchor links with #name
      url = WYSIWYG_Core.stringToRegex(stripAnchorUrl);
      // exact replacing of url. regex: src="<url>"
      if(exact) {
        regex = eval("/(href=\")(" + url + ")(#[^\"]*)/gi");
        content = content.replace(regex, "$1$3");
      }
      // not exect replacing of url. regex: <url>
      else {
        regex = eval("/(" + url + ")(.+)/gi");
        content = content.replace(regex, "$2");
      }


      // stip off anchor links with #name (only for local system)
      url = WYSIWYG_Core.getDocumentUrl(document);
      var pos = url.lastIndexOf("/");
      if(pos != -1) {
        url = url.substring(pos + 1, url.length);
        url = WYSIWYG_Core.stringToRegex(url);
        // exact replacing of url. regex: src="<url>"
        if(exact) {
          regex = eval("/(href=\")(" + url + ")(#[^\"]*)/gi");
          content = content.replace(regex, "$1$3");
        }
        // not exect replacing of url. regex: <url>
        else {
          regex = eval("/(" + url + ")(.+)/gi");
          content = content.replace(regex, "$2");
        }
      }
    }

    return content;
  },

  /* ---------------------------------------------------------------------- *\
    Function    : updateTextArea()
    Description : Updates the text area value with the HTML source of the WYSIWYG
    Arguments   : n   - The editor identifier (the textarea's ID)
  \* ---------------------------------------------------------------------- */
  updateTextArea: function(n) {
    // on update switch editor back to html mode
    if(this.viewTextMode[n]) { this.viewText(n); }
    // get inner HTML
    var content = this.getEditorWindow(n).document.body.innerHTML;
    content = content.replace('<img src="../assets/ajax-loader.gif" id="caret">','');
    /* if(WYSIWYG_Core.isFF){
      content = this.replaceAll(content,"</ul>");
      content = this.replaceAll(content,"ul_tag_edi");
      content = this.replaceAll(content,"<br>");
      //replace blank <p> tags
      content = this.replaceAll(content,"<p></p>");
     }*/
    this.getEditorWindow(n).document.body.innerHTML ="";
      this.getEditorWindow(n).document.body.innerHTML =content;
    // strip off defined URLs on IE
    //content = this.stripURLPath(n, content);

    // replace all decimal color strings with hex color strings
    content = WYSIWYG_Core.replaceRGBWithHexColor(content);
    // remove line breaks before content will be updated
    if(this.config[n].ReplaceLineBreaks) { content = content.replace(/(\r\n)|(\n)/ig, ""); }
    // set content back in textarea
    $(n).value = content;

  },


    replaceAll: function(content,replaceString1){
    var temp = content;
    var index = temp.indexOf(replaceString1);
    var firstEle = false;
        while(index != -1){

      if(replaceString1!="<br>"){
          if(replaceString1!="</ul>"){
              if(replaceString1!="<p></p>")
                temp = temp.replace(replaceString1,"</ul>");
              else
                temp = temp.replace(replaceString1," ");
          }else{
            temp = temp.replace(replaceString1,"ul_tag_edi<br>");
          }
      }
      else{
        if(!firstEle){
                  temp = temp.replace("<br>","<p>");
                  firstEle = true;
        }
        else{
          var temp2 = temp.replace("<br>","</p>");

          if(temp2.indexOf("<br>")==-1){
            temp = temp.replace("<br>","</p>");
          }else{
            temp = temp.replace("<br>","</p><p>");
          }

        }
      }
            index = temp.indexOf(replaceString1);
        }
        return temp;
  },

  /* ---------------------------------------------------------------------- *\
    Function    : hideToolbars()
    Description : Hide all toolbars
    Usage       : WYSIWYG.hideToolbars(n)
    Arguments   : n - The editor identifier (the textarea's ID)
  \* ---------------------------------------------------------------------- */
  hideToolbars: function(n) {
    for(var i=0;i<this.config[n].Toolbar.length;i++) {
      var toolbar = $("toolbar" + i + "_" + n);
      if(toolbar) { toolbar.style.display = "none"; }
    }
  },

  /* ---------------------------------------------------------------------- *\
    Function    : showToolbars()
    Description : Display all toolbars
    Usage       : WYSIWYG.showToolbars(n)
    Arguments   : n - The editor identifier (the textarea's ID)
  \* ---------------------------------------------------------------------- */
  showToolbars: function(n) {
    for(var i=0;i<this.config[n].Toolbar.length;i++) {
      var toolbar = $("toolbar" + i + "_" + n);
      if(toolbar) { toolbar.style.display = ""; }
    }
  },

  /* ---------------------------------------------------------------------- *\
    Function    : hideStatusBar()
    Description : Hide the status bar
    Usage       : WYSIWYG.hideStatusBar(n)
    Arguments   : n - The editor identifier (the textarea's ID)
  \* ---------------------------------------------------------------------- */
  hideStatusBar: function(n) {
    var statusbar = $('wysiwyg_statusbar_' + n);
    if(statusbar) {  statusbar.style.display = "none"; }
  },

  /* ---------------------------------------------------------------------- *\
    Function    : showStatusBar()
    Description : Display the status bar
    Usage       : WYSIWYG.showStatusBar(n)
    Arguments   : n - The editor identifier (the textarea's ID)
  \* ---------------------------------------------------------------------- */
  showStatusBar: function(n) {
    var statusbar = $('wysiwyg_statusbar_' + n);
    if(statusbar) { statusbar.style.display = ""; }
  },

  /**
   * Finds the node with the given tag name in the given range
   *
   * @param {String} tagName Parent tag to find
   * @param {Range} range Current range
   */
  findParent: function(parentTagName, range){
    parentTagName = parentTagName.toUpperCase();
    var rangeWorking;
    var elmWorking = null;
    try {
      if(!WYSIWYG_Core.isMSIE) {
        var node = range.startContainer;
        var pos = range.startOffset;
        if(node.nodeType != 3) { node = node.childNodes[pos]; }
        return WYSIWYG_Core.findParentNode(parentTagName, node);
      }
      else {
        elmWorking = (range.length > 0) ? range.item(0): range.parentElement();
        elmWorking = WYSIWYG_Core.findParentNode(parentTagName, elmWorking);
        if(elmWorking != null) return elmWorking;

        rangeWorking = range.duplicate();
        rangeWorking.collapse(true);
        rangeWorking.moveEnd("character", 1);
        if (rangeWorking.text.length>0) {
          while (rangeWorking.compareEndPoints("EndToEnd", range) < 0){
              rangeWorking.move("Character");
              if (null != this.findParentTag(parentTagName, rangeWorking)){
                 return this.findParentTag(parentTagName, rangeWorking);
              }
           }
         }
         return null;
      }
    }
    catch(e) {
      return null;
    }
  },

  /**
   * Get the acutally tag of the given range
   *
   * @param {Range} range Current range
   */
  getTag: function(range) {
    try {
        if(!WYSIWYG_Core.isMSIE) {
        var node = range.startContainer;
        var pos = range.startOffset;
        if(node.nodeType != 3) { node = node.childNodes[pos]; }

        if(node.nodeName && node.nodeName.search(/#/) != -1) {
          return node.parentNode;
        }
        return node;
      }
      else {
        if(range.length > 0) {
          return range.item(0);
        }
        else if(range.parentElement()) {
          return range.parentElement();
        }
      }
      return null;
    }
    catch(e) {
      return null;
    }
  },

  /**
   * Get the parent node of the given node
   *
   * @param {DOMElement} element - Element which parent will be returned
   */
  getParent: function(element) {
    if(element.parentNode) {
      return element.parentNode;
    }
    return null;
  },

  /* ---------------------------------------------------------------------- *\
    Function    : getTextRange()
    Description : Get the text range object of the given element
    Usage       : WYSIWYG.getTextRange(element)
    Arguments   : element - An element of which you get the text range object
  \* ---------------------------------------------------------------------- */
  getTextRange: function(element){
    var range = element.parentTextEdit.createTextRange();
    range.moveToElementText(element);
    return range;
  },

  pasteStuff: function(n){
    var sel = this.getRange(this.getSelection(n));


    var stripedHTML = "";
    if(WYSIWYG_Core.isFF) {
      var s =this.getSelection(n).getRangeAt(0);
      var docFrag =  s.extractContents();
      var doc = this.getEditorWindow(n).document;
      var paragraphTag = doc.createElement('div');
      var childNodes = new Array();
      for(var i=0; i <docFrag.childNodes.length;i++){
        childNodes[i] = docFrag.childNodes[i];
      }
      for(var i=0;i<childNodes.length;i++){
        paragraphTag.appendChild(childNodes[i]);
      }
      stripedHTML  = this.stripHTML(paragraphTag.innerHTML);
    }
    else{
      if(sel.htmlText == null || sel.htmlText == ''){
        alert('Please select some text to format.');
        return;
      }
      stripedHTML  = this.stripHTML(sel.htmlText);
    }
    if(this.viewTextMode[n]) { this.viewText(n); }
    this.insertHTML(stripedHTML,n);
  },


  stripHTML: function(oldString) {

     var newString = "";
     var inTag = false;
    oldString = oldString.replace(/<br\/>/ig,'_r_n');
    oldString = oldString.replace(/<br>/ig,'_r_n');
      oldString = oldString.replace(/<br \/>/ig,'_r_n');
      oldString = oldString.replace(/<\/p>/ig,'_r_n');
      oldString = oldString.replace(/<\/h1>/ig,'_r_n');
      oldString = oldString.replace(/<\/h2>/ig,'_r_n');
      oldString = oldString.replace(/<\/h3>/ig,'_r_n');

       for(var i = 0; i < oldString.length; i++) {

        if(oldString.charAt(i) == '<') {
          inTag = true;
        }
        if(oldString.charAt(i) == '>') {
          if(oldString.charAt(i+1)=="<")
          {
            //dont do anything
          }
          else
          {
            inTag = false;
            i++;
          }
        }

        if(!inTag) {
          newString += oldString.charAt(i);
        }

       }
      newString = newString.replace(/(?:_r_n)/ig,"<br>");
      return newString;
  },



  /* ---------------------------------------------------------------------- *\
    Function    : invertIELineBreakCapability()
    Description : Inverts the line break capability of IE (Thx to richyrich)
            Normal: ENTER = <p> , SHIFT + ENTER = <br>
            Inverted: ENTER = <br>, SHIFT + ENTER = <p>
    Usage       : WYSIWYG.invertIELineBreakCapability(n)
    Arguments   : n   - The editor identifier (the textarea's ID)
  \* ---------------------------------------------------------------------- */
  invertIELineBreakCapability: function(n) {

    var editor = this.getEditorWindow(n);
    var sel;
    // validate if the press key is the carriage return key
    if (editor.event.keyCode==13) {
        if (!editor.event.shiftKey) {
      /*  sel = this.getRange(this.getSelection(n));
        sel.pasteHTML("<br>");
              editor.event.cancelBubble = true;
              editor.event.returnValue = false;
              sel.select();
              sel.moveEnd("character", 1);
              sel.moveStart("character", 1);
              sel.collapse(false);
              return false;*/
                this.parseAndremoveUnwanted(n)
      }
          else {
              /*sel = this.getRange(this.getSelection(n));
          sel.pasteHTML("<p>");
              editor.event.cancelBubble = true;
              editor.event.returnValue = false;
              sel.select();
              sel.moveEnd("character", 1);
              sel.moveStart("character", 1);
              sel.collapse(false);
              return false;*/
        }

    }
  },



  /* ---------------------------------------------------------------------- *\
    Function    : invertIELineBreakCapabilityGeneric()
    Description : ENTER = <p> , SHIFT + ENTER = <br>

    Usage       : WYSIWYG.invertIELineBreakCapabilityGeneric(n,event)
    Arguments   : n   - The editor identifier (the textarea's ID)
            event   - The event identifier
  \* ---------------------------------------------------------------------- */
  invertIELineBreakCapabilityGeneric: function(n,evt) {

    var editor = this.getEditorWindow(n);
    var sel;
    // validate if the press key is the carriage return key
    var nbr = (editor.event)?editor.event.keyCode:evt.which;
    var nodeTree = this.getNodeTree(n);
    var isBullet=false;
    if(nodeTree!=null){
      var tag = nodeTree[0];
      if(tag.parentNode.nodeName=="LI"){
        var parent = tag.parentNode;
        tag = parent;
      }else if( tag.parentNode.parentNode.nodeName=="LI" ){
        var parent = tag.parentNode.parentNode;
        tag = parent;
      }
      if(tag.nodeName=="LI" || tag.nodeName=="UL" || tag.nodeName=="H1" || tag.nodeName=="H2" || tag.nodeName=="H3"){
        isBullet=true;
      }

    }

    if (nbr==13) {
      if (!evt.shiftKey & !isBullet) {
        WYSIWYG_Core.execCommand(n, "InsertParagraph",'');
      }
      this.parseAndremoveUnwanted(n,tag)
    }
  },
  /* ---------------------------------------------------------------------- *\
    Function    : selectNode()
    Description : Select a node within the current editor
    Usage       : WYSIWYG.selectNode(n, level)
    Arguments   : n   - The editor identifier (the textarea's ID)
            level - identifies the level of the element which will be selected
  \* ---------------------------------------------------------------------- */
  selectNode: function(n, level) {

    var sel = this.getSelection(n);
    var range = this.getRange(sel);
    var parentnode = this.getTag(range);
    var i = 0;

    for (var node=parentnode; (node && (node.nodeType == 1)); node=node.parentNode) {
      if (i == level) {
        this.nodeSelection(n, node);
      }
      i++;
    }

    this.updateStatusBar(n);
  },

  /* ---------------------------------------------------------------------- *\
    Function    : nodeSelection()
    Description : Do the node selection
    Usage       : WYSIWYG.nodeSelection(n, node)
    Arguments   : n   - The editor identifier (the textarea's ID)
            node - The node which will be selected
  \* ---------------------------------------------------------------------- */
  nodeSelection: function(n, node) {

    var doc = this.getEditorWindow(n).document;
    var sel = this.getSelection(n);
    var range = this.getRange(sel);

    if(!WYSIWYG_Core.isMSIE) {
      if (node.nodeName == "BODY") {
        range.selectNodeContents(node);
      } else {
        range.selectNode(node);
      }

      /*
      if (endNode) {
        try {
          range.setStart(node, startOffset);
          range.setEnd(endNode, endOffset);
        } catch(e) {
        }
      }
      */

      if (sel) { sel.removeAllRanges(); }
      if (sel) { sel.addRange(range);   }
    }
    else {
      // MSIE may not select everything when BODY is selected -
      // start may be set to first text node instead of first non-text node -
      // no known workaround
      if ((node.nodeName == "TABLE") || (node.nodeName == "IMG") || (node.nodeName == "INPUT") || (node.nodeName == "SELECT") || (node.nodeName == "TEXTAREA")) {
        try {
          range = doc.body.createControlRange();
          range.addElement(node);
          range.select();
        }
        catch(e) { }
      }
      else {
        range = doc.body.createTextRange();
        if (range) {
          range.collapse();
          if (range.moveToElementText) {
            try {
              range.moveToElementText(node);
              range.select();
            } catch(e) {
              try {
                range = doc.body.createTextRange();
                range.moveToElementText(node);
                range.select();
              }
              catch(e) {}
            }
          } else {
            try {
              range = doc.body.createTextRange();
              range.moveToElementText(node);
              range.select();
            }
            catch(e) {}
          }
        }
      }
    }
  }
}

/********************************************************************
 * openWYSIWYG core functions Copyright (c) 2006 openWebWare.com
 * Contact us at devs@openwebware.com
 * This copyright notice MUST stay intact for use.
 *
 * $Id: wysiwyg.js,v 1.41 2012/02/21 12:07:04 ajay Exp $
 ********************************************************************/
var WYSIWYG_Core = {

  /**
   * Holds true if browser is MSIE, otherwise false
   */
  isMSIE: navigator.appName == "Microsoft Internet Explorer" ? true : false,

  /**
   * Holds true if browser is Firefox (Mozilla)
   */
  isFF: !document.all && document.getElementById && !this.isOpera,

  /**
   * Holds true if browser is Opera, otherwise false
   */
  isOpera: navigator.appName == "Opera" ? true : false,

  /**
   * Trims whitespaces of the given string
   *
   * @param str String
   * @return Trimmed string
   */
  trim: function(str) {
    return str.replace(/^\s*|\s*$/g,"");
  },

  /**
   * Determine if the given parameter is defined
   *
   * @param p Parameter
   * @return true/false dependents on definition of the parameter
   */
  defined: function(p) {
    return typeof p == "undefined" ? false : true;
  },

  /**
   * Determine if the browser version is compatible
   *
   * @return true/false depending on compatiblity of the browser
   */
  isBrowserCompatible: function() {
    // Validate browser and compatiblity
    if ((navigator.userAgent.indexOf('Safari') != -1 ) || !document.getElementById || !document.designMode){
      //no designMode (Safari lies)
         return false;
    }
    return true;
  },

  /**
   * Set the style attribute of the given element.
   * Private method to solve the IE bug while setting the style attribute.
   *
   * @param {DOMElement} node The element on which the style attribute will affect
   * @param {String} style Stylesheet which will be set
   */
  _setStyleAttribute: function(node, style) {
    if(style == null) return;
    var styles = style.split(";");
    var pos;
    for(var i=0;i<styles.length;i++) {
      var attributes = styles[i].split(":");
      if(attributes.length == 2) {
        try {
          var attr = WYSIWYG_Core.trim(attributes[0]);
          while((pos = attr.search(/-/)) != -1) {
            var strBefore = attr.substring(0, pos);
            var strToUpperCase = attr.substring(pos + 1, pos + 2);
            var strAfter = attr.substring(pos + 2, attr.length);
            attr = strBefore + strToUpperCase.toUpperCase() + strAfter;
          }
          var value = WYSIWYG_Core.trim(attributes[1]).toLowerCase();
          node.style[attr] = value;
        }
        catch (e) {
          alert(e);
        }
      }
    }
  },

  /**
   * Fix's the issue while getting the attribute style on IE
   * It's return an object but we need the style string
   *
   * @private
   * @param {DOMElement} node Node element
   * @return {String} Stylesheet
   */
  _getStyleAttribute: function(node) {
    if(this.isMSIE) {
      return node.style['cssText'].toLowerCase();
    }
    else {
      return node.getAttribute("style");
    }
  },

  /**
   * Set an attribute's value on the given node element.
   *
   * @param {DOMElement} node Node element
   * @param {String} attr Attribute which is set
   * @param {String} value Value of the attribute
   */
  setAttribute: function(node, attr, value) {
    if(value == null || node == null || attr == null) return;
    if(attr.toLowerCase() == "style") {
      this._setStyleAttribute(node, value);
    }
    else {
      node.setAttribute(attr, value);
    }
  },

  /**
   * Removes an attribute on the given node
   *
   * @param {DOMElement} node Node element
   * @param {String} attr Attribute which will be removed
   */
  removeAttribute: function(node, attr) {
    node.removeAttribute(attr, false);
  },

  /**
   * Get the vale of the attribute on the given node
   *
   * @param {DOMElement} node Node element
   * @param {String} attr Attribute which value will be returned
   */
  getAttribute: function(node, attr) {
    if(node == null || attr == null) return;
    if(attr.toLowerCase() == "style") {
      return this._getStyleAttribute(node);
    }
    else {
      return node.getAttribute(attr);
    }
  },

  /**
   * Get the path out of an given url
   *
   * @param {String} url The url with is used to get the path
   */
  getDocumentPathOfUrl: function(url) {
    var path = null;

    // if local file system, convert local url into web url
    url = url.replace(/file:\/\//gi, "file:///");
    url = url.replace(/\\/gi, "\/");
    var pos = url.lastIndexOf("/");
    if(pos != -1) {
      path = url.substring(0, pos + 1);
    }
    return path;
  },

  /**
   * Get the documents url, convert local urls to web urls
   *
   * @param {DOMElement} doc Document which is used to get the url
   */
  getDocumentUrl: function(doc) {
    // if local file system, convert local url into web url
    var url = doc.URL;
    url = url.replace(/file:\/\//gi, "file:///");
    url = url.replace(/\\/gi, "\/");
    return url;
  },

  /**
   * Find a parent node with the given name, of the given start node
   *
   * @param {String} tagName - Tag name of the node to find
   * @param {DOMElement} node - Node element
   */
  findParentNode: function(tagName, node) {
    while (node.tagName != "HTML") {
        if (node.tagName == tagName){
          return node;
        }
        node = node.parentNode;
     }
     return null;
  },

  /**
   * Cancel the given event.
   *
   * @param e Event which will be canceled
   */
  cancelEvent: function(e) {
    if (!e) return false;
    if (this.isMSIE) {
      e.returnValue = false;
      e.cancelBubble = true;
    } else {
      e.preventDefault();
      e.stopPropagation && e.stopPropagation();
    }
    return false;
  },

  /**
   * Converts a RGB color string to hex color string.
   *
   * @param color RGB color string
   * @param Hex color string
   */
  toHexColor: function(color) {
    color = color.replace(/^rgb/g,'');
    color = color.replace(/\(/g,'');
    color = color.replace(/\)/g,'');
    color = color.replace(/ /g,'');
    color = color.split(',');
    var r = parseFloat(color[0]).toString(16).toUpperCase();
    var g = parseFloat(color[1]).toString(16).toUpperCase();
    var b = parseFloat(color[2]).toString(16).toUpperCase();
    if (r.length<2) { r='0'+r; }
    if (g.length<2) { g='0'+g; }
    if (b.length<2) { b='0'+b; }
    return r + g + b;
  },

  /**
   * Converts a decimal color to hex color string.
   *
   * @param Decimal color
   * @param Hex color string
   */
  _dec_to_rgb: function(value) {
    var hex_string = "";
    for (var hexpair = 0; hexpair < 3; hexpair++) {
      var myByte = value & 0xFF;            // get low byte
      value >>= 8;                          // drop low byte
      var nybble2 = myByte & 0x0F;          // get low nybble (4 bits)
      var nybble1 = (myByte >> 4) & 0x0F;   // get high nybble
      hex_string += nybble1.toString(16);   // convert nybble to hex
      hex_string += nybble2.toString(16);   // convert nybble to hex
    }
    return hex_string.toUpperCase();
  },

  /**
   * Replace RGB color strings with hex color strings within a string.
   *
   * @param {String} str RGB String
   * @param {String} Hex color string
   */
  replaceRGBWithHexColor: function(str) {
    if(str == null) return "";
    // find all decimal color strings
    var matcher = str.match(/rgb\([0-9 ]+,[0-9 ]+,[0-9 ]+\)/gi);
    if(matcher) {
      for(var j=0; j<matcher.length;j++) {
        var regex = eval("/" + WYSIWYG_Core.stringToRegex(matcher[j]) + "/gi");
        // replace the decimal color strings with hex color strings
        str = str.replace(regex, "#" + this.toHexColor(matcher[j]));
      }
    }
    return str;
  },

  /**
   * Execute the given command on the given editor
   *
   * @param n The editor's identifier
   * @param cmd Command which is execute
   */
  execCommand: function(n, cmd, value) {
    if(typeof(value) == "undefined") value = null;
    // firefox BackColor problem fixed
    if(cmd == 'BackColor' && WYSIWYG_Core.isFF) cmd = 'HiliteColor';

    // firefox cut, paste and copy
    if(WYSIWYG_Core.isFF && (cmd == "Cut" || cmd == "Paste" || cmd == "Copy")) {
      try {
        WYSIWYG.getEditorWindow(n).document.execCommand(cmd, false, value);
      }
      catch(e) {
        if(confirm("Copy/Cut/Paste is not available in Mozilla and Firefox\nDo you want more information about this issue?")) {
          window.open('http://www.mozilla.org/editor/midasdemo/securityprefs.html');
        }
      }
    }

    else {
      WYSIWYG.getEditorWindow(n).document.execCommand(cmd, false, value);
    }
  },

  /**
   * Parse a given string to a valid regular expression
   *
   * @param {String} string String to be parsed
   * @return {RegEx} Valid regular expression
   */
  stringToRegex: function(string) {

    string = string.replace(/\//gi, "\\/");
    string = string.replace(/\(/gi, "\\(");
    string = string.replace(/\)/gi, "\\)");
    string = string.replace(/\[/gi, "\\[");
    string = string.replace(/\]/gi, "\\]");
    string = string.replace(/\+/gi, "\\+");
    string = string.replace(/\$/gi, "\\$");
    string = string.replace(/\*/gi, "\\*");
    string = string.replace(/\?/gi, "\\?");
    string = string.replace(/\^/gi, "\\^");
    string = string.replace(/\\b/gi, "\\\\b");
    string = string.replace(/\\B/gi, "\\\\B");
    string = string.replace(/\\d/gi, "\\\\d");
    string = string.replace(/\\B/gi, "\\\\B");
    string = string.replace(/\\D/gi, "\\\\D");
    string = string.replace(/\\f/gi, "\\\\f");
    string = string.replace(/\\n/gi, "\\\\n");
    string = string.replace(/\\r/gi, "\\\\r");
    string = string.replace(/\\t/gi, "\\\\t");
    string = string.replace(/\\v/gi, "\\\\v");
    string = string.replace(/\\s/gi, "\\\\s");
    string = string.replace(/\\S/gi, "\\\\S");
    string = string.replace(/\\w/gi, "\\\\w");
    string = string.replace(/\\W/gi, "\\\\W");

    return string;
  },

  /**
   * Add an event listener
   *
   * @param obj Object on which the event will be attached
   * @param ev Kind of event
   * @param fu Function which is execute on the event
   */
  addEvent: function(obj, ev, fu) {
    if (obj.attachEvent)
      obj.attachEvent("on" + ev, fu);
    else
      obj.addEventListener(ev, fu, false);
  },

  /**
   * Remove an event listener
   *
   * @param obj Object on which the event will be attached
   * @param ev Kind of event
   * @param fu Function which is execute on the event
   */
  removeEvent:  function(obj, ev, fu) {
    if (obj.attachEvent)
      obj.detachEvent("on" + ev, fu);
    else
      obj.removeEventListener(ev, fu, false);
  },

  /**
   * Includes a javascript file
   *
   * @param file Javascript file path and name
   */
  includeJS: function(file) {
    var script = document.createElement("script");
    this.setAttribute(script, "type", "text/javascript");
    this.setAttribute(script, "src", file);
    var heads = document.getElementsByTagName("head");
    for(var i=0;i<heads.length;i++) {
      heads[i].appendChild(script);
    }
  },

  /**
   * Includes a stylesheet file
   *
   * @param file Stylesheet file path and name
   */
  includeCSS: function(path) {
    var link = document.createElement("link");
    this.setAttribute(link, "rel", "stylesheet");
    this.setAttribute(link, "type", "text/css");
    this.setAttribute(link, "href", path);
    var heads = document.getElementsByTagName("head");
    for(var i=0;i<heads.length;i++) {
      heads[i].appendChild(link);
    }
  },

  /**
   * Get the screen position of the given element.
   *
   * @param {HTMLObject} elm1 Element which position will be calculate
   * @param {HTMLObject} elm2 Element which is the last one before calculation stops
   * @param {Object} Left and top position of the given element
   */
  getElementPosition: function(elm1, elm2) {
    var top = 0, left = 0;
    while (elm1 && elm1 != elm2) {
      left += elm1.offsetLeft;
      top += elm1.offsetTop;
      elm1 = elm1.offsetParent;
    }
    return {left : left, top : top};
  },

  /**
   * Get the window size
   * @private
   */
  windowSize: function() {
    if (window.innerWidth) {
        return {width: window.innerWidth, height: window.innerHeight};
      }
    else if (document.body && document.body.offsetWidth) {
        return {width: document.body.offsetWidth, height: document.body.offsetHeight};
      }
    else {
        return {width: 0, height: 0};
      }
  }
}

/**
 * Context menu object
 */
var WYSIWYG_ContextMenu = {

  html: "",
  contextMenuDiv: null,

  /**
   * Init function
   *
   * @param {String} n Editor identifier
   */
  init: function(n) {
    var doc = WYSIWYG.getEditorWindow(n).document;

    // create context menu div
    this.contextMenuDiv = document.createElement("div");
    this.contextMenuDiv.className = "wysiwyg-context-menu-div";
    this.contextMenuDiv.setAttribute("class", "wysiwyg-context-menu-div");
    this.contextMenuDiv.style.display = "none";
    this.contextMenuDiv.style.position = "absolute";
    this.contextMenuDiv.style.zIndex = 9999;
    this.contextMenuDiv.style.left = "0";
    this.contextMenuDiv.style.top = "0";
    this.contextMenuDiv.unselectable = "on";
    document.body.insertBefore(this.contextMenuDiv, document.body.firstChild);

    // bind event listeners
  //  WYSIWYG_Core.addEvent(doc, "contextmenu", function context(e) { WYSIWYG_ContextMenu.show(e, n); });
  //  WYSIWYG_Core.addEvent(doc, "click", function context(e) { WYSIWYG_ContextMenu.close(); });
  //  WYSIWYG_Core.addEvent(doc, "keydown", function context(e) { WYSIWYG_ContextMenu.close(); });
  //  WYSIWYG_Core.addEvent(document, "click", function context(e) { WYSIWYG_ContextMenu.close(); });
  },

  /**
   * Show the context menu
   *
   * @param e Event
   * @param n Editor identifier
   */
  show: function(e, n) {
    if(this.contextMenuDiv == null) return false;

    var ifrm = WYSIWYG.getEditor(n);
    var doc = WYSIWYG.getEditorWindow(n).document;

    // set the context menu position
    var pos = WYSIWYG_Core.getElementPosition(ifrm);
    var x = WYSIWYG_Core.isMSIE ? pos.left + e.clientX : pos.left + (e.pageX - doc.body.scrollLeft);
    var y = WYSIWYG_Core.isMSIE ? pos.top + e.clientY : pos.top + (e.pageY - doc.body.scrollTop);

    this.contextMenuDiv.style.left = x + "px";
    this.contextMenuDiv.style.top = y + "px";
    this.contextMenuDiv.style.visibility = "visible";
    this.contextMenuDiv.style.display = "block";

    // call the context menu, mozilla needs some time
    window.setTimeout("WYSIWYG_ContextMenu.output('" + n + "')", 10);

    WYSIWYG_Core.cancelEvent(e);
    return false;
  },

  /**
   * Output the context menu items
   *
   * @param n Editor identifier
   */
  output: function (n) {

    // get selection
    var sel = WYSIWYG.getSelection(n);
    var range = WYSIWYG.getRange(sel);

    // get current selected node
    var tag = WYSIWYG.getTag(range);
    if(tag == null) { return; }

    // clear context menu
    this.clear();

    // Determine kind of nodes
    var isImg = (tag.nodeName == "IMG") ? true : false;
    var isLink = (tag.nodeName == "A") ? true : false;

    // Selection is an image or selection is a text with length greater 0
    var len = 0;
    if(WYSIWYG_Core.isMSIE)
      len = (document.selection && range.text) ? range.text.length : 0;
    else
      len = range.toString().length;
    var sel = len != 0 || isImg;

    // Icons
    var iconLink = { enabled: WYSIWYG.config[n].ImagesDir + WYSIWYG.ToolbarList["createlink"][3], disabled: WYSIWYG.config[n].ImagesDir + WYSIWYG.ToolbarList["createlink"][2]};
    var iconImage = { enabled: WYSIWYG.config[n].ImagesDir + WYSIWYG.ToolbarList["insertimage"][3], disabled: WYSIWYG.config[n].ImagesDir + WYSIWYG.ToolbarList["insertimage"][2]};
    var iconDelete = { enabled: WYSIWYG.config[n].ImagesDir + WYSIWYG.ToolbarList["delete"][3], disabled: WYSIWYG.config[n].ImagesDir + WYSIWYG.ToolbarList["delete"][2]};
    var iconCopy = { enabled: WYSIWYG.config[n].ImagesDir + WYSIWYG.ToolbarList["copy"][3], disabled: WYSIWYG.config[n].ImagesDir + WYSIWYG.ToolbarList["copy"][2]};
    var iconCut = { enabled: WYSIWYG.config[n].ImagesDir + WYSIWYG.ToolbarList["cut"][3], disabled: WYSIWYG.config[n].ImagesDir + WYSIWYG.ToolbarList["cut"][2]};
    var iconPaste = { enabled: WYSIWYG.config[n].ImagesDir + WYSIWYG.ToolbarList["paste"][3], disabled: WYSIWYG.config[n].ImagesDir + WYSIWYG.ToolbarList["paste"][2]};

    // Create context menu html
    this.html += '<table class="wysiwyg-context-menu" border="0" cellpadding="0" cellspacing="0">';

    // Add items
    this.addItem(n, 'Copy', iconCopy, 'Copy', sel);
    this.addItem(n, 'Cut', iconCut, 'Cut', sel);
    this.addItem(n, 'Paste', iconPaste, 'Paste', true);
    this.addSeperator();
    this.addItem(n, 'CreateLink', iconLink, 'Create or Modify Link...', sel || isLink);
    this.addItem(n, 'RemoveNode', iconDelete, 'Remove', true);

    this.html += '</table>';
    this.contextMenuDiv.innerHTML = this.html;
  },

  /**
   * Close the context menu
   */
  close: function() {
    this.contextMenuDiv.style.visibility = "hidden";
    this.contextMenuDiv.style.display = "none";
  },

  /**
   * Clear context menu
   */
  clear: function() {
    this.contextMenuDiv.innerHTML = "";
    this.html = "";
  },

  /**
   * Add context menu item
   *
   * @param n editor identifier
   * @param cmd Command
   * @param icon Icon which is diabled
   * @param title Title of the item
   * @param disabled If item is diabled
   */
  addItem: function(n, cmd, icon, title, disabled) {
    var item = '';

    if(disabled) {
      item += '<tr>';
      item += '<td class="icon"><a href="javascript:WYSIWYG.execCommand(\'' + n + '\',\'' + cmd + '\', null);"><img src="' + icon.enabled + '" border="0"></a></td>';
      item += '<td onmouseover="this.className=\'mouseover\'" onmouseout="this.className=\'\'" onclick="WYSIWYG.execCommand(\'' + n + '\', \'' + cmd + '\', null);WYSIWYG_ContextMenu.close();"><a href="javascript:void(0);">' + title + '</a></td>';
      item += '</tr>';
    }
    else {
      item += '<tr>';
      item += '<td class="icon"><img src="' + icon.disabled + '" border="0"></td>';
      item += '<td onmouseover="this.className=\'mouseover\'" onmouseout="this.className=\'\'"><span class="disabled">' + title + '</span></td>';
      item += '</tr>';
    }

    this.html += item;
  },

  /**
   * Add seperator to context menu
   */
  addSeperator: function() {
    var output = '';
    output += '<tr>';
    output += '<td colspan="2" style="text-align:center;"><hr size="1" color="#C9C9C9" width="95%"></td>';
    output += '</tr>';
    this.html += output;
  }
}

/**
 * Table object
 */
var WYSIWYG_Table = {

  /**
   *
   */
  create: function(n, tbl) {

    // get editor
    var doc = WYSIWYG.getEditorWindow(n).document;
    // get selection and range
    var sel = WYSIWYG.getSelection(n);
    var range = WYSIWYG.getRange(sel);
    var table = null;

    // get element from selection
    if(WYSIWYG_Core.isMSIE) {
      if(sel.type == "Control" && range.length == 1) {
        range = WYSIWYG.getTextRange(range(0));
        range.select();
      }
    }

    // find a parent TABLE element
    //table = WYSIWYG.findParent("table", range);

    // check if parent is found
    //var update = (table == null) ? false : true;
    //if(!update) table = tbl;
    table = tbl;

    // add rows and cols
    var rows = WYSIWYG_Core.getAttribute(tbl, "tmprows");
    var cols = WYSIWYG_Core.getAttribute(tbl, "tmpcols");
    WYSIWYG_Core.removeAttribute(tbl, "tmprows");
    WYSIWYG_Core.removeAttribute(tbl, "tmpcols");
    for(var i=0;i<rows;i++) {
      var tr = doc.createElement("tr");
      for(var j=0;j<cols;j++){
        var td = createTD();
        tr.appendChild(td);
      }
      table.appendChild(tr);
    }

    // on update exit here
    //if(update) { return; }

    // Check if IE or Mozilla (other)
    if (WYSIWYG_Core.isMSIE) {
      range.pasteHTML(table.outerHTML);
    }
    else {
      WYSIWYG.insertNodeAtSelection(table, n);
    }

    // refresh table highlighting
    this.refreshHighlighting(n);




     // functions
    function createTD() {
      var td = doc.createElement("td");
      td.innerHTML = "&nbsp;";
      return td;
    }

  },

  /**
   * Enables the table highlighting
   *
   * @param {String} n The editor identifier (the textarea's ID)
   */
  refreshHighlighting: function(n) {
    var doc = WYSIWYG.getEditorWindow(n).document;
    var tables = doc.getElementsByTagName("table");
    for(var i=0;i<tables.length;i++) {
      this._enableHighlighting(tables[i]);
    }
    var tds = doc.getElementsByTagName("td");
    for(var i=0;i<tds.length;i++) {
      this._enableHighlighting(tds[i]);
    }
  },

  /**
   * Enables the table highlighting
   *
   * @param {String} n The editor identifier (the textarea's ID)
   */
  disableHighlighting: function(n) {
    var doc = WYSIWYG.getEditorWindow(n).document;
    var tables = doc.getElementsByTagName("table");
    for(var i=0;i<tables.length;i++) {
      this._disableHighlighting(tables[i]);
    }
    var tds = doc.getElementsByTagName("td");
    for(var i=0;i<tds.length;i++) {
      this._disableHighlighting(tds[i]);
    }

  },

  /**
   * @private
   */
  _enableHighlighting: function(node) {
    var style = WYSIWYG_Core.getAttribute(node, "style");
    if(style == null) style = " ";
    //alert("ENABLE: ELM = " + node.tagName + "; STYLE = " + style);
    WYSIWYG_Core.removeAttribute(node, "prevstyle");
    WYSIWYG_Core.setAttribute(node, "prevstyle", style);
    WYSIWYG_Core.setAttribute(node, "style", "border:1px dashed #AAAAAA;");
  },

  /**
   * @private
   */
  _disableHighlighting: function(node) {
    var style = WYSIWYG_Core.getAttribute(node, "prevstyle");
    //alert("DISABLE: ELM = " + node.tagName + "; STYLE = " + style);
    // if no prevstyle is defined, the table is not in highlighting mode
    if(style == null || style == "") {
      this._enableHighlighting(node);
      return;
    }
    WYSIWYG_Core.removeAttribute(node, "prevstyle");
    WYSIWYG_Core.removeAttribute(node, "style");
    WYSIWYG_Core.setAttribute(node, "style", style);
  }
}


/**
 * Get an element by it's identifier
 *
 * @param id Element identifier
 */
function $(id) {
  return document.getElementById(id);
}

/**
 * Emulates insertAdjacentHTML(), insertAdjacentText() and
 * insertAdjacentElement() three functions so they work with Netscape 6/Mozilla
 * by Thor Larholm me@jscript.dk
 */
if(typeof HTMLElement!="undefined" && !HTMLElement.prototype.insertAdjacentElement){
  HTMLElement.prototype.insertAdjacentElement = function (where,parsedNode) {
    switch (where){
    case 'beforeBegin':
      this.parentNode.insertBefore(parsedNode,this);
      break;
    case 'afterBegin':
      this.insertBefore(parsedNode,this.firstChild);
      break;
    case 'beforeEnd':
      this.appendChild(parsedNode);
      break;
    case 'afterEnd':
      if (this.nextSibling) {
        this.parentNode.insertBefore(parsedNode,this.nextSibling);
      }
      else {
        this.parentNode.appendChild(parsedNode);
      }
      break;
    }
  };

  HTMLElement.prototype.insertAdjacentHTML = function (where,htmlStr) {
    var r = this.ownerDocument.createRange();
    r.setStartBefore(this);
    var parsedHTML = r.createContextualFragment(htmlStr);
    this.insertAdjacentElement(where,parsedHTML);
  };


  HTMLElement.prototype.insertAdjacentText = function (where,txtStr) {
    var parsedText = document.createTextNode(txtStr);
    this.insertAdjacentElement(where,parsedText);
  };
}



