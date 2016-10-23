var app = angular.module('myApp');
app.service('AllPeople', function($http) {
    
    this.findFullName = function (key) {
        if (!this.allPersonList) {
            this.getPeopleOutOfStorage();
        }
        var fullName = key;
        this.allPersonList.people.forEach(  function(item) {
            if (item.uid == key) {
                fullName = item.name;
            }
        });
        return fullName;
    }
    this.findMatchingPeople = function(query) {
        var res = [];
        var q = query.toLowerCase();
        this.allPersonList.people.forEach( function(person) {
            if (person.name.toLowerCase().indexOf(q)<0 && person.uid.toLowerCase().indexOf(q)<0) {
                return;
            }
            var nix = {};
            nix.name = person.name; 
            nix.uid  = person.uid; 
            nix.key  = person.key; 
            res.push(nix);
        });
        return res;
    }
    this.refreshCache = function() {
        this.allPersonList = {people:[]};
        this.fetchPeople();
    }
    
    
    this.fetchPeople = function () {
        $http.get("../../AllPeople.json")
        .success( function(data) {
            this.allPersonList = data;
            sessionStorage.setItem('allPersonList', JSON.stringify(this.allPersonList));
            console.log("AllPeople retrieved, count = "+data.people.length);
        })
        .error( function(data) {
            console.log("AllPeople FAILURE: ", data);
        });
    }
    this.getPeopleOutOfStorage = function () {
        var allPersonStr = sessionStorage.getItem('allPersonList');
        if (allPersonStr) {
            this.allPersonList = JSON.parse(allPersonStr);
        }
        else {
            this.allPersonList = {people:[]};
            sessionStorage.setItem('allPersonList', JSON.stringify(this.allPersonList));
        }
    }
    this.getPeopleOutOfStorage();
    if (this.allPersonList.people.length==0) {
        this.fetchPeople();
    }
    console.log("AllPeople service is running, cache = "+this.allPersonList.people.length);
    
});