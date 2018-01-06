var myApp = angular.module('myApp');
myApp.config(['$translateProvider', function($translateProvider) {

        var dxp_monitor_de ={
            "Workspaces" : "Arbeitsbereiche",
            "Top Action Items":"Top-Aktionselemente",
            "Upcoming Meetings":"Bevorstehende Treffen"
        };

        var dxp_monitor_en ={
            "Workspaces" : "Workspaces"
        };

        $translateProvider
            .translations('en', dxp_monitor_en)
            .translations('de', dxp_monitor_de)
            .preferredLanguage('en')
            .fallbackLanguage('en')
            .useSanitizeValueStrategy('escape')
        ;
}]);