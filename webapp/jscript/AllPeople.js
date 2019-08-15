var app = angular.module('myApp');
app.service('AllPeople', function($http) {
    
    //get around the JavaScript problems with 'this'
    var AllPeople = this;
    var fetchedAt = 0;
    
    //There is a problem with pages continually asking for new user lists after the 
    //page has been logged out, so as soon as the first error is encountered fetching
    //a list, disable any additional fetching until the page is refreshed.
    var refreshDisabled = false;
    
    AllPeople.getSiteObject = function(site) {
        if (!site) {
            throw "AllPeople.getSiteObject %% Need to specify a tenant";
        }
        if (!AllPeople.allPersonList) {
            AllPeople.getPeopleOutOfStorage();
        }
        if (!AllPeople.allPersonBySite[site]) {
            AllPeople.allPersonBySite[site] = {people:[],validTime:0};
        }
        AllPeople.refreshListIfNeeded(site);
        return AllPeople.allPersonBySite[site];
    }
    
    AllPeople.findFullName = function (key, site) {
        var siteObj = AllPeople.getSiteObject(site);
        var fullName = key;
        siteObj.people.forEach(  function(item) {
            if (item.uid == key) {
                fullName = item.name;
            }
        });
        return fullName;
    }
    AllPeople.findUserKey = function (key, site) {
        var siteObj = AllPeople.getSiteObject(site);
        var thisKey = key;
        siteObj.people.forEach(  function(item) {
            if (item.uid == key) {
                thisKey = item.key;
            }
        });
        return thisKey;
    }
    AllPeople.findMatchingPeople = function(query, site) {
        var siteObj = AllPeople.getSiteObject(site);
        var res = [];
        var q = query.toLowerCase();
        siteObj.people.forEach( function(person) {
            if (person.name.toLowerCase().indexOf(q)<0 && person.uid.toLowerCase().indexOf(q)<0) {
                return;
            }
            res.push(person);
        });
        return res;
    }
    AllPeople.findPerson = function(query, site) {
        var siteObj = AllPeople.getSiteObject(site);
        var res = null;
        var q = query.toLowerCase();
        siteObj.people.forEach( function(person) {
            if (person.name.toLowerCase().indexOf(q)<0 && person.uid.toLowerCase().indexOf(q)<0) {
                return;
            }
            res = person;
        });
        return res;
    }
    AllPeople.findUserFromID = function(email, site) {
        var siteObj = AllPeople.getSiteObject(site);
        var res = {};
        siteObj.people.forEach(  function(item) {
            if (item.uid == email || item.key == email) {
                res = item;
            }
        });
        if (!res.uid) {
            res.uid = email;
        }
        if (!res.name) {
            res.name = email;
        }
        res.image = AllPeople.imageName(res);
        return res;
    }
    AllPeople.findUsersFromID = function(emailList, site) {
        if (!site) {
            throw "AllPeople.findUsersFromID %% Need to specify a tenant";
        }
        var res = [];
        emailList.forEach( function(email) {
            res.push(AllPeople.findUserFromID(email, site));
        });
        return res;
    }
    AllPeople.imageName = function(player) {
        if (player.key) {
            return player.key+".jpg";
        }
        else {
            var lc = player.uid.toLowerCase();
            var ch = lc.charAt(0);
            var i =1;
            while(i<lc.length && (ch<'a'||ch>'z')) {
                ch = lc.charAt(i); i++;
            }
            return "fake-"+ch+".jpg";
        }
    }
    
    
    AllPeople.refreshListIfNeeded = function(site) {
        if (refreshDisabled) {
            return;
        }
        var curTime = new Date().getTime();
        if (!AllPeople.allPersonBySite[site]) {
            AllPeople.allPersonBySite[site] = {people:[],validTime:0};
        }
        var siteObj = AllPeople.allPersonBySite[site]
        if (siteObj.validTime>curTime) {
            return;
        }
        AllPeople.refreshCache(site);
    }
    AllPeople.refreshCache = function(site) {        
        if (!site) {
            throw "AllPeople.refreshCache %% Need to specify a tenant";
        }
        var url = "../../"+site+"/$/SitePeople.json";
        $http.get(url)
        //$http.get("../../AllPeople.json")
        .success( function(data) {
            console.log("Read people from", url, data);
            data.validTime = new Date().getTime() + 3600000;
            AllPeople.allPersonBySite[site] = data;
            sessionStorage.setItem('allPersonBySite', JSON.stringify(AllPeople.allPersonBySite));
            console.log("allPersonBySite["+site+"] retrieved, count = "+data.people.length
                        +", valid until ="+new Date(data.validTime));
        })
        .error( function(data) {
            //we got an error and the most common error is because user logged out.
            //this prevents the continued polling after logging out.
            refreshDisabled = true;
            console.log("allPersonBySite["+site+"] FAILURE: ", data);
        });
    }
    AllPeople.getPeopleOutOfStorage = function () {
        var allPersonStr = sessionStorage.getItem('allPersonBySite');
        if (allPersonStr) {
            AllPeople.allPersonBySite = JSON.parse(allPersonStr);
        }
        else {
            if (!AllPeople.allPersonBySite) {
                AllPeople.allPersonBySite = {};
            }
            sessionStorage.setItem('allPersonBySite', JSON.stringify(AllPeople.allPersonBySite));
        }
    }
    
    AllPeople.getPeopleOutOfStorage();
    
});