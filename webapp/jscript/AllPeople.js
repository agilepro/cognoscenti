var app = angular.module('myApp');
app.service('AllPeople', function($http) {
    
    //get around the JavaScript problems with 'this'
    var AllPeople = this;
    var nextFetchTime = 0;
    
    AllPeople.findFullName = function (key) {
        if (!AllPeople.allPersonList) {
            AllPeople.getPeopleOutOfStorage();
        }
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
        AllPeople.allPersonList = {people:[]};
        AllPeople.fetchPeople();
    }
    
    
    AllPeople.fetchPeople = function () {
        $http.get("../../AllPeople.json")
        .success( function(data) {
            AllPeople.allPersonList = data;
            sessionStorage.setItem('allPersonList', JSON.stringify(AllPeople.allPersonList));
            console.log("AllPeople retrieved, count = "+AllPeople.allPersonList.people.length);
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
            AllPeople.allPersonList = {people:[]};
            sessionStorage.setItem('allPersonList', JSON.stringify(AllPeople.allPersonList));
        }
    }
    AllPeople.getPeopleOutOfStorage();
    if (!AllPeople.allPersonList.people) {
        console.log("STRANGE: allPersonList object was corrupted somehow");
        AllPeople.allPersonList.people = [];
    }
    if (AllPeople.allPersonList.people.length==0) {
        AllPeople.fetchPeople();
    }
    console.log("AllPeople service is running, cache = "+AllPeople.allPersonList.people.length);
    
});