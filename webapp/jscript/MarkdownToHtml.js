
var NOTHING      = 0;
var PARAGRAPH    = 1;
var BULLET       = 2;
var HEADER       = 3;
var PREFORMATTED = 4;

var majorState = 0;
var majorLevel = 0;
var isBold = false;
var isItalic = false;
var userKey;


function convertMarkdownToHtml(markdown) {
    if (!markdown) {
        return "";
    }
    var lineArray = markdown.split("\n");
    var res = "";
    lineArray.forEach( function(line) {
        res += formatLine(line);
    });
    res += terminate();
    return res;
}

function formatLine(line) {
    var res = "";
    var isIndented = line.indexOf(" ")==0;
    line = line.trim();
    if (line.length == 0) {
        res += terminate();
    } else if (line.indexOf("!!!")==0) {
        res += startHeader(line, 3);
    } else if (line.indexOf("!!")==0) {
        res += startHeader(line, 2);
    } else if (line.indexOf("!")==0) {
        res += startHeader(line, 1);
    } else if (line.indexOf("*****")==0) {
        res += startBullet(line, 5);
    } else if (line.indexOf("****")==0) {
        res += startBullet(line, 4);
    } else if (line.indexOf("***")==0) {
        res += startBullet(line, 3);
    } else if (line.indexOf("**")==0) {
        res += startBullet(line, 2);
    } else if (line.indexOf("*")==0) {
        res += startBullet(line, 1);
    } else if (isIndented) {
        // continue whatever mode there is
        res += scanForStyle(line, 0);
    }else {
        if (majorState != PARAGRAPH && majorState != PREFORMATTED) {
            res += startParagraph();
        }
        res += scanForStyle(line, 0);
    }
    return res;
}

function terminate() {
    var res = "";
    if (isBold) {
        res += "</b>";
    }
    if (isItalic) {
        res += "</i>";
    }
    if (majorState == NOTHING) {
    } else if (majorState == PARAGRAPH) {
        res += "</p>\n";
    } else if (majorState == PREFORMATTED) {
        res += "</pre>\n";
    } else if (majorState == BULLET) {
        res += "</li>\n";
        while (majorLevel > 0) {
            res += "</ul>\n";
            majorLevel--;
        }
    } else if (majorState == HEADER) {
        switch (majorLevel) {
        case 1:
            res += "</h3>\n";
            break;
        case 2:
            res += "</h2>\n";
            break;
        case 3:
            res += "</h1>\n";
            break;
        }
    }
    majorState = NOTHING;
    majorLevel = 0;
    isBold = false;
    isItalic = false;
    return res;
}

function startBullet(line, level) {
    res = "";
    if (majorState != BULLET) {
        res += terminate();
        majorState = BULLET;
    } else {
        res += "</li>\n";
    }
    while (majorLevel > level) {
        res += "</ul>\n";
        majorLevel--;
    }
    while (majorLevel < level) {
        res += "<ul>\n";
        majorLevel++;
    }
    res += "<li>";
    res += scanForStyle(line, level);
    return res;
}

function startHeader(line, level) {
    var res = terminate();
    majorState = HEADER;
    majorLevel = level;
    switch (level) {
    case 1:
        res += "<h3>";
        break;
    case 2:
        res += "<h2>";
        break;
    case 3:
        res += "<h1>";
        break;
    }
    res += scanForStyle(line, level).trim();
    return res;
}

function scanForStyle(line, scanStart){
    var pos = scanStart;
    var last = line.length;
    var res = "";
    while (pos < last) {
        var ch = line.charAt(pos);
        switch (ch) {
        case '&':
            res += "&amp;";
            pos++;
            continue;
        case '"':
            res += "&quot;";
            pos++;
            continue;
        case '<':
            res += "&lt;";
            pos++;
            continue;
        case '>':
            res += "&gt;";
            pos++;
            continue;
        case '[':
            var pos2 = line.indexOf(']', pos);
            if (pos2 > pos + 1) {
                var linkURL = line.substring(pos + 1, pos2);
                res += outputProperLink(linkURL);
                pos = pos2 + 1;
            } else if (pos2 == pos + 1) {
                pos = pos + 2;
            } else {
                pos = pos + 1;
            }
            continue;
        case '_':
            if (line.length > pos + 1 && line.charAt(pos + 1) == '_') {
                pos += 2;
                if (isBold) {
                    res += "</b>";
                } else {
                    res += "<b>";
                }
                isBold = !isBold;
                continue;
            }
            break;
        case '\'':
            if (line.length > pos + 1 && line.charAt(pos + 1) == '\'') {
                pos += 2;
                if (isItalic) {
                    res += "</i>";
                } else {
                    res += "<i>";
                }
                isItalic = !isItalic;
                continue;
            }
            break;
        case 'º':
            if (line.length > pos + 1) {
                var escape = line.charAt(pos + 1);
                if (escape == '[' || escape == '\'' || escape == '_'  || escape == 'º') {
                    //only these characters can be escaped at this time
                    //if one of these, eliminate the º, and output the following character without interpretation
                    ch = escape;
                    pos++;
                }
            }
            break;
        }
        res += ch;
        pos++;
    }
    //res += "\n";
    return res;
}

function startParagraph() {
    var res = terminate();
    res += "<p>";
    majorState = PARAGRAPH;
    majorLevel = 0;
    return res;
}


function outputProperLink(linkContentText) {
    linkContentText = linkContentText.trim();
    var barPos = linkContentText.indexOf("|");
    var linkText = linkContentText;
    var linkAddr = linkContentText;
    var titleValue = linkContentText;
    
    if (barPos >= 0) {
        //We have both a link text, and a link address, so use them.
        linkText = linkContentText.substring(0,barPos).trim();
        linkAddr = linkContentText.substring(barPos+1).trim();
    }

    var isExternal = (linkAddr.indexOf("http")==0 && linkAddr.indexOf("/") >= 0);
    var target = null;
    if (isExternal) {
        target = "_blank";
        titleValue = "external link: "+titleValue;
    }
    
    var res = "<a href=\"";
    res += linkAddr;
    res += "\" title=\"";
    res += titleValue;
    if (target != null) {
        res += "\" target=\"";
        res += textToHtml(target);
    }
    res += "\">";
    res += textToHtml(linkText);
    res += "</a>";
    return res;
}

function textToHtml(line) {
    var pos = 0;
    var last = line.length;
    var res = "";
    while (pos < last) {
        var ch = line.charAt(pos);
        pos++;
        switch (ch) {
            case '&':
            res += "&amp;";
            continue;
        case '"':
            res += "&quot;";
            continue;
        case '<':
            res += "&lt;";
            continue;
        case '>':
            res += "&gt;";
            continue;
        default:
            res += ch;
        }
    }
    return res;
}

