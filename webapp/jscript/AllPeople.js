WCACHE = {
    getObj: function(key) {
        let box = this.getBox(key);
        console.log("GETTING "+key, box.value);
        return box.value;
    },
    getAge: function(key) {
        let box = this.getBox(key);
        return box.time;
    },
    putObj: function(key, newValue, timestamp) {
        let box = this.getBox(key);
        if (timestamp > box.time) {
            box.time = timestamp;
            box.value = newValue;
            console.log("SETTING "+key, box.value);
            localStorage.setItem("WCACHE"+key, JSON.stringify(box));
        }
    },
    getBox: function(key) {
        try {
            let boxStr = localStorage.getItem("WCACHE"+key);
            if (boxStr) {
                box = JSON.parse(boxStr);
                return box;
            }
        }
        catch (e) {
            //ignore parsing errors
        } 
        return {time: 0,value: {}};
    }
};



function getSiteProxy(newBaseUrl, newSiteId) {
    return {
        baseUrl: newBaseUrl,
        siteId: newSiteId,
        getWorkspaceProxy: function(wsId, scope) {
            return getWorkspaceProxy(this.baseUrl, this.siteId, wsId, scope);
        }
    }
}

function getWorkspaceProxy(newBaseUrl, newSiteId, newWorkspaceId, scope) {
    return {
        baseUrl: newBaseUrl,
        siteId: newSiteId,
        wsId: newWorkspaceId,
        scope: scope,
        failure: function(data) {console.log("FAILURE", data)},
        apiCall: function(address, success) {
            let url = this.baseUrl + "t/" +this.siteId+ "/" +this.wsId+ "/" + address;
            let cache = WCACHE.getObj(url);
            if (cache) {
                success(cache);
            };
            var scope = this.scope;
            SLAP.getJSON(url, function(data) {success(data); WCACHE.putObj(url, data, new Date().getTime()); scope.$apply()}, this.failure);
            //SLAP.getJSON(url, success, this.failure);
        },
        getMeetingList: function(success) {
            this.apiCall("meetingList.json", success);
        },
        getTaskAreas: function(success) {
            this.apiCall("taskAreas.json", success);
        },
        getTopics: function(success) {
            this.apiCall("topicList.json", success);
        },
        getMeeting: function(id, success) {
            this.apiCall("meetingRead.json?id="+id, success);
        },
        getAllActionItems: function(success) {
            this.apiCall("allActionsList.json", success);
        }
    }
}

var app = angular.module('myApp');
app.service('AllPeople', function($http) {
    
    //get around the JavaScript problems with 'this'
    var AllPeople = this;
    var fetchedAt = 0;
    var pendingRefresh = false;
    
    //There is a problem with pages continually asking for new user lists after the 
    //page has been logged out, so as soon as the first error is encountered fetching
    //a list, disable any additional fetching until the page is refreshed.
    var refreshDisabled = false;
    
    AllPeople.getSiteObject = function(site) {
        if (!site) {
            throw "AllPeople.getSiteObject %% Need to specify a site";
        }
        if (!AllPeople.allPersonBySite) {
            AllPeople.getPeopleOutOfStorage();
        }
        if (!AllPeople.allPersonBySite[site]) {
            AllPeople.allPersonBySite[site] = {people:[],validTime:0};
        }
        var siteObj = AllPeople.allPersonBySite[site];
        if (siteObj.validTime<new Date().getTime() && !siteObj.pendingRefresh) {
            AllPeople.internalRefreshCache(site, siteObj);
        }
        return siteObj;
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
        if (!player) {
            return "fake-~.jpg";
        }
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
        var siteObj = AllPeople.getSiteObject(site);
        if (siteObj.validTime>curTime || siteObj.pendingRefresh) {
            return;
        }
        AllPeople.internalRefreshCache(site, siteObj);
    }
    AllPeople.clearCache = function(site) { 
        var siteObj = AllPeople.getSiteObject(site);
        siteObj.validTime = 0;
        AllPeople.internalRefreshCache(site, siteObj);
    }    
    AllPeople.internalRefreshCache = function(site, siteObj) {        
        if (siteObj.pendingRefresh || refreshDisabled) {
            return;
        }
        siteObj.pendingRefresh = true;
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