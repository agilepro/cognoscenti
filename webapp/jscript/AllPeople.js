var app = angular.module('myApp');
app.service('AllPeople', function($http) {
    
    //get around the JavaScript problems with 'this'
    var AllPeople = this;
    var fetchedAt = 0;
    
    AllPeople.findFullName = function (key) {
        if (!AllPeople.allPersonList) {
            AllPeople.getPeopleOutOfStorage();
        }
        AllPeople.refreshListIfNeeded();
        var fullName = key;
        AllPeople.allPersonList.people.forEach(  function(item) {
            if (item.uid == key) {
                fullName = item.name;
            }
        });
        return fullName;
    }
    AllPeople.findUserKey = function (key) {
        if (!AllPeople.allPersonList) {
            AllPeople.getPeopleOutOfStorage();
        }
        AllPeople.refreshListIfNeeded();
        var thisKey = key;
        AllPeople.allPersonList.people.forEach(  function(item) {
            if (item.uid == key) {
                thisKey = item.key;
            }
        });
        return thisKey;
    }
    AllPeople.findMatchingPeople = function(query) {
        if (!AllPeople.allPersonList) {
            AllPeople.getPeopleOutOfStorage();
        }
        AllPeople.refreshListIfNeeded();
        var res = [];
        var q = query.toLowerCase();
        AllPeople.allPersonList.people.forEach( function(person) {
            if (person.name.toLowerCase().indexOf(q)<0 && person.uid.toLowerCase().indexOf(q)<0) {
                return;
            }
            res.push(person);
        });
        return res;
    }
    AllPeople.findPerson = function(query) {
        if (!AllPeople.allPersonList) {
            AllPeople.getPeopleOutOfStorage();
        }
        AllPeople.refreshListIfNeeded();
        var res = null;
        var q = query.toLowerCase();
        AllPeople.allPersonList.people.forEach( function(person) {
            if (person.name.toLowerCase().indexOf(q)<0 && person.uid.toLowerCase().indexOf(q)<0) {
                return;
            }
            res = person;
        });
        return res;
    }
    AllPeople.refreshCache = function() {
        AllPeople.allPersonList = {people:[],validTime:0};
        AllPeople.refreshListIfNeeded();
    }
    
    
    AllPeople.refreshListIfNeeded = function () {
        var curTime = new Date().getTime();
        if (AllPeople.allPersonList.validTime>curTime) {
            return;
        }
        if (fetchedAt>curTime-10000) {
            return;
        }
        fetchedAt = curTime;
        $http.get("../../AllPeople.json")
        .success( function(data) {
            AllPeople.allPersonList = data;
            AllPeople.allPersonList.validTime = new Date().getTime() + 3600000;
            sessionStorage.setItem('allPersonList', JSON.stringify(AllPeople.allPersonList));
            console.log("AllPeople retrieved, count = "+AllPeople.allPersonList.people.length
                        +", valid until ="+new Date(AllPeople.allPersonList.validTime));
        })
        .error( function(data) {
            console.log("AllPeople FAILURE: ", data);
        });
    }
    AllPeople.getPeopleOutOfStorage = function () {
        var allPersonStr = sessionStorage.getItem('allPersonList');
        if (allPersonStr) {
            AllPeople.allPersonList = JSON.parse(allPersonStr);
        }
        else {
            AllPeople.allPersonList = {people:[],validTime:0};
            sessionStorage.setItem('allPersonList', JSON.stringify(AllPeople.allPersonList));
        }
    }
    
    AllPeople.getPeopleOutOfStorage();
    if (!AllPeople.allPersonList.people) {
        console.log("STRANGE: allPersonList object was corrupted somehow");
        AllPeople.allPersonList.people = [];
        AllPeople.allPersonList.validTime = 0;
    }
    AllPeople.refreshListIfNeeded();
    console.log("AllPeople service is running, cache = "+AllPeople.allPersonList.people.length 
              +", valid until ="+new Date(AllPeople.allPersonList.validTime));
    
});