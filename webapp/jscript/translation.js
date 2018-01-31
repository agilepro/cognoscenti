var myApp = angular.module('myApp');
myApp.config(['$translateProvider', function($translateProvider) {

    var dxp_monitor_de ={
        "Workspaces" : "Arbeitsbereiche",
        "Top Action Items":"Aktionselemente",
        "Planned Meetings":"Geplante Treffen",
        "Need to Respond": "Aufmerksamkeit",
        "Need to Complete": "Unvollendet",
        "Workspaces you Watch": "Arbeitsbereiche",
        "Sites you Manage": "Standorten",
        "See all...": "Mehr...",
        "Options":"Optionen",
        "User Alerts":"Benutzerwarnungen",
        "A list of things that have changed in the pages that you watch":"Eine Liste der Dinge, die sich auf den von Ihnen beobachteten Seiten geändert haben",
        "Recalculate":"Neu berechnen",
        "Use this option if you want to see changes that occurred in the past 24 hours":"Verwenden Sie diese Option, wenn Sie Änderungen sehen möchten, die in den letzten 24 Stunden aufgetreten sind",
        "Advance Review Date 1 Year":"Vorabüberprüfungsdatum 1 Jahr",
        "Sets the review date to be one year later than currently set":"Legt das Überprüfungsdatum auf ein Jahr später fest als derzeit festgelegt"
    };

    var dxp_monitor_en ={
        "Workspaces" : "Workspaces"
    };

    function getAcceptedLanguages() { 
        // navigator.languages:    Chrome & FF 
        // navigator.language:     Safari & Others 
        // navigator.userLanguage: IE & Others 
        if (window.navigator) { 
          if (window.navigator.languages ){
              return window.navigator.languages;
          }
        }
        //if (root) {
        //  if (root.navigator) {
        //      return [root.navigator.language || root.navigator.userLanguage]; 
        //  }
        //}
        return []; 
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
    
    $translateProvider
        .translations('en', dxp_monitor_en)
        .translations('de', dxp_monitor_de)
        .preferredLanguage(getPreferredLanguage())
        .fallbackLanguage('en')
        .useSanitizeValueStrategy('escape')
    ;
        
             
}]);