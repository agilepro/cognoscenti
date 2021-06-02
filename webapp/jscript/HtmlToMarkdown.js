/**
 * HTML2Markdown - An HTML to Markdown converter.
 *
 * This implementation uses HTML DOM parsing for conversion. Parsing code was
 * abstracted out in a parsing function which should be easy to remove in favor
 * of other parsing libraries.
 *
 * Converted MarkDown was tested with ShowDown library for HTML rendering. And
 * it tries to create MarkDown that does not confuse ShowDown when certain
 * combination of HTML tags come together.
 *
 * @author Himanshu Gilani
 * @author Kates Gasis (original author)
 *
 */

/**
 * HTML2Markdown
 * @param html - html string to convert
 * @return converted markdown text
 */
function HTML2Markdown(html, opts) {
    var logging = false;
    var nodeList = [];
    var listTagStack = [];
    var linkAttrStack = [];
    var isNewLine = true;
    var isBlankLine = true;

    opts = opts || {};

    var markdownTags = {
        "hr": "----\n\n",
        "br": "  \n",
        "title": "# ",
        "h1": "!!! ",
        "h2": "!! ",
        "h3": "! ",
        "h4": "! ",
        "h5": "! ",
        "h6": "! ",
        "b": "__",
        "strong": "__",
        "i": "''",
        "em": "''",
        "span": " ",
        "ul": "*",
        "ol": "*"
    };

    function assureNewLine() {
        if (!isNewLine) {
            nodeList.push("\n");
            isNewLine = true;
        }
    }
    function assureBlankLine() {
        if (!isNewLine) {
            nodeList.push("\n");
            isNewLine = true;
        }
        if (!isBlankLine) {
            nodeList.push("\n");
            isBlankLine = true;
        }
    }
    function addText(text) {
        nodeList.push(text);
        isNewLine = false;
        isBlankLine = false;
    }

    function getListMarkdownPrefix() {
        var listPrefix = "";
        if(listTagStack) {
            for ( var i = 0; i < listTagStack.length; i++) {
                listPrefix += "*";
            }
        }
        listPrefix += " ";
        return listPrefix;
    }

    function convertAttrs(attrs) {
        var attributes = {};
        for(var k in attrs) {
            var attr = attrs[k];
            attributes[attr.name] = attr.value;
        }
        console.log("ATTRIBS:", attributes);
        return attributes;
    }

    function peek(list) {
        if(list && list.length > 0) {
            return list[list.length-1];
        }
        return "";
    }

    function peekTillNotEmpty(list) {
        if(!list) {
            return "";
        }

        for(var i = list.length - 1; i>=0; i-- ){
            if(list[i] != "") {
                return list[i];
            }
        }
        return "";
    }

    function removeIfEmptyTag(start) {
        console.log("removeIfEmptyTag:", nodeList);
        var cleaned = false;
        if(start == peekTillNotEmpty(nodeList)) {
            while(peek(nodeList) != start) {
                nodeList.pop();
            }
            nodeList.pop();
            cleaned = true;
        }
        return cleaned;
    }

    function sliceText(start) {
        var text = [];
        while(nodeList.length > 0 && peek(nodeList) != start) {
            var t = nodeList.pop();
            text.unshift(t);
        }
        return text.join("");
    }

    function block(isEndBlock) {
        var lastItem = nodeList.pop();
        if (!lastItem) {
            return;
        }

        if(!isEndBlock) {
            var block;
            if(/\s*\n\n\s*$/.test(lastItem)) {
                lastItem = lastItem.replace(/\s*\n\n\s*$/, "\n\n");
                block = "";
            } else if(/\s*\n\s*$/.test(lastItem)) {
                lastItem = lastItem.replace(/\s*\n\s*$/, "\n");
                block = "\n";
            } else if(/\s+$/.test(lastItem)) {
                block = "\n\n";
            } else {
                block = "\n\n";
            }

            nodeList.push(lastItem);
            nodeList.push(block);
        } else {
            nodeList.push(lastItem);
            if(!lastItem.endsWith("\n")) {
                nodeList.push("\n\n");
            }
        }
    }

    function listBlock() {
        //assureNewLine();
        if(nodeList.length > 0) {
            var li = peek(nodeList);

            if(!li.endsWith("\n")) {
                nodeList.push("\n");
            }
        } else {
            nodeList.push("\n");
        }
    }

    if(!html) {
        //no html means no markdown
        return "";
    }

    var parserObj = {
        start: function(tag, attrs, unary) {
            tag = tag.toLowerCase();
            if(logging) {
                console.log("start: "+ tag);
            }

            if(unary && (tag != "br" && tag != "hr" && tag != "img")) {
                return;
            }

            switch (tag) {
                case "br":
                    assureNewLine();
                    //we don't really handle the BR case
                    //nodeList.push(markdownTags[tag]);
                    break;
                case "hr":
                    assureNewLine();
                    addText(markdownTags[tag]);
                    break;
                case "title":
                case "h1":
                case "h2":
                case "h3":
                case "h4":
                case "h5":
                case "h6":
                    assureNewLine();
                    addText(markdownTags[tag]);
                    break;
                case "b":
                case "strong":
                case "i":
                case "em":
                case "dfn":
                case "var":
                case "cite":
                    addText(markdownTags[tag]);
                    break;
                case "p":
                case "div":
                case "td":
                    assureBlankLine();
                    break;
                case "ul":
                case "ol":
                case "dl":
                    listTagStack.push(markdownTags[tag]);
                    break;
                case "li":
                case "dt":
                    assureNewLine();
                    addText(getListMarkdownPrefix());
                    break;
                case "a":
                    var attribs = convertAttrs(attrs);
                    linkAttrStack.push(attribs);
                    addText("[");
                    break;
                case "img":
                    var attribs = convertAttrs(attrs);
                    var alt, title, url;

                    if (!attribs["src"]) {
                        break;
                    }
                    var url = getNormalizedUrl(attribs["src"]);
                    if(!url) {
                        break;
                    }

                case "span":
                case "header":
                case "form":
                case "section":
                case "aside":
                case "small":
                case "footer":
                case "table":
                case "tr":
                case "th":
                    //ignore all the above
                    break;
                default:
                    addText("(?"+tag+"?)");
            }
        },
        chars: function(text) {
            if(text.trim() == "") {
                //this is the empty case, and not sure why we would
                //ever want to push an empty item
                nodeList.push("");
                return;
            }

            //only if NOT empty string
            //convert multiple spaces into single spaces
            text = text.replace(/\s+/g, " ");
            //find the last non empty thing in there
            var prevText = peekTillNotEmpty(nodeList);
            //if there are any spaces on end of line, eliminate them (from beginning of line???)
            if(/\s+$/.test(prevText)) {
                text = text.replace(/^\s+/g, "");
            }

            if(logging) {
                console.log("text: "+ text);
            }

            addText(text);
        },
        end: function(tag) {
            tag = tag.toLowerCase();
            if(logging) {
                console.log("end: "+ tag);
            }

            switch (tag) {
                case "title":
                case "h1":
                case "h2":
                case "h3":
                case "h4":
                case "h5":
                case "h6":
                    assureNewLine();
                    break;
                case "p":
                case "div":
                //case "td":
                    assureNewLine();
                    break;
                case "b":
                case "strong":
                case "i":
                case "em":
                case "dfn":
                case "var":
                case "cite":
                    if(!removeIfEmptyTag(markdownTags[tag])) {
                        //grabs everything after the start tag and trims spaces
                        nodeList.push(sliceText(markdownTags[tag]).trim());
                        //now add the trailing markdown
                        nodeList.push(markdownTags[tag]);
                    }
                    break;
                case "a":
                    //get everything after the opening markdown
                    var text = sliceText("[");
                    //consolidate multiple spaces into single spaces
                    text = text.replace(/\s+/g, " ");
                    text = text.trim();

                    //if there is no text afterall, then just forget about it
                    if(text == "") {
                        nodeList.pop();
                        break;
                    }

                    //get the link detail
                    var attrs = linkAttrStack.pop();
                    var url;
                    if (attrs["href"] &&  attrs["href"] != "") {
                        url = getNormalizedUrl(attrs["href"]);
                    }

                    if(url == "") {
                        //if there is no URL, then get rid of link, but keep the text
                        nodeList.pop();
                        addText(text);
                        break;
                    }

                    addText(text);
                    addText("|" + url + "]");
                    break;
                case "ul":
                case "ol":
                case "dl":
                    listTagStack.pop();
                    break;
                case "li":
                case "dt":
                    assureNewLine();
                    break;
                case "br":
                case "hr":
                case "img":
                case "span":
                case "header":
                case "form":
                case "section":
                case "aside":
                case "small":
                case "footer":
                case "table":
                case "tr":
                case "td":
                case "th":
                    //ignore all the above
                    break;
                default:
                    addText("(?/"+tag+"?)");
            }
        }
    };
    var paramObj = {"nodesToIgnore": ["script", "noscript", "object", "iframe", "frame", "head", "style", "label"]};

    HTMLParser(html, parserObj, paramObj);

    return nodeList.join("").trim();
}

function getNormalizedUrl(s) {
    var urlBase = location.href;
    var urlDir  = urlBase.replace(/\/[^\/]*$/, '/');
    var urlPage = urlBase.replace(/#[^\/#]*$/, '');

    var url;
    if(/^[a-zA-Z]([a-zA-Z0-9 -.])*:/.test(s)) {
        // already absolute url
        url = s;
    } else if(/^\x2f/.test(s)) {// %2f --> /
        // url is relative to site
        location.protocol != "" ? url = location.protocol + "//" : url ="";
        url+= location.hostname;
        if(location.port != "80") {
            url+=":"+location.port;
        }
        url += s;
    } else if(/^#/.test(s)) {
        // url is relative to page
        url = urlPage + s;
    } else {
        url = urlDir + s;
    }
    return encodeURI(url);
}

if (typeof exports != "undefined") {
    exports.HTML2Markdown = HTML2Markdown;
}

if (typeof exports != "undefined") {
    exports.HTML2MarkDown = HTML2MarkDown;
}

/* add the useful functions to String object*/
if (typeof String.prototype.trim != 'function') {
    String.prototype.trim = function() {
        return replace(/^\s+|\s+$/g,"");
    };
}

if (typeof String.prototype.isNotEmpty != 'function') {
    String.prototype.isNotEmpty = function() {
        if (/\S/.test(this)) {
            return true;
        } else {
            return false;
        }
    };
}

if (typeof String.prototype.replaceAll != 'function') {
    String.prototype.replaceAll = function(stringToFind,stringToReplace){
        var temp = this;
        var index = temp.indexOf(stringToFind);
            while(index != -1){
                temp = temp.replace(stringToFind,stringToReplace);
                index = temp.indexOf(stringToFind);
            }
            return temp;
    };
}

if (typeof String.prototype.startsWith != 'function') {
    String.prototype.startsWith = function(str) {
        return this.indexOf(str) == 0;
    };
}

if (typeof String.prototype.endsWith != 'function') {
    String.prototype.endsWith = function(suffix) {
        return this.match(suffix+"$") == suffix;
    };
}

if (typeof Array.prototype.indexOf != 'function') {
    Array.prototype.indexOf = function(obj, fromIndex) {
        if (fromIndex == null) {
            fromIndex = 0;
        } else if (fromIndex < 0) {
            fromIndex = Math.max(0, this.length + fromIndex);
        }
        for ( var i = fromIndex, j = this.length; i < j; i++) {
            if (this[i] === obj)
                return i;
        }
        return -1;
    };
}