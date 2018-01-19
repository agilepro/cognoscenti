console.log("TRANSLATION");
var myApp = angular.module('myApp');
console.log("TRANSLATION", myApp);
myApp.config(['$translateProvider', function($translateProvider) {

    console.log("FUNCTION(translateProvider)");
    var dxp_monitor_de ={
        "Workspaces" : "Arbeitsbereiche",
        "Top Action Items":"Aktionselemente",
        "Planned Meetings":"Geplante Treffen",
        "Need to Respond": "Aufmerksamkeit",
        "Need to Complete": "Unvollendet",
        "Workspaces you Watch": "Arbeitsbereiche",
        "Sites you Manage": "Standorten",
        "See all...": "Mehr..."
    };

    var dxp_monitor_en ={
        "Workspaces" : "Workspaces"
    };

    function getAcceptedLanguages() { 
        // navigator.languages:    Chrome & FF 
        // navigator.language:     Safari & Others 
        // navigator.userLanguage: IE & Others 
        if (window.navigator) { 
          return window.navigator.languages || [root.navigator.language || root.navigator.userLanguage]; 
        } else { 
           return []; 
        } 
    };
    function getPreferredLanguage() {
        var langs = getAcceptedLanguages();
        var pos = 0;
        while (pos<langs.length) {
            if (langs[pos].startsWith("en")) {
                return "en";
            }
            if (langs[pos].startsWith("de")) {
                return "de";
            }
        }
        return "en";
    }
    console.log("LANGAUGE:", getAcceptedLanguages(), getPreferredLanguage());
    
    $translateProvider
        .translations('en', dxp_monitor_en)
        .translations('de', dxp_monitor_de)
        .preferredLanguage(getPreferredLanguage())
        .fallbackLanguage('en')
        .useSanitizeValueStrategy('escape')
    ;
        
             
}]);