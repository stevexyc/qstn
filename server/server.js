var sessions = new Meteor.Collection('Sessions');
var comments = new Meteor.Collection('Comments');

Meteor.startup(function(){
    var admin = Meteor.users.findOne({username: "admin"});
    if ((admin === undefined) || (admin === 'undefined')) {
    	Accounts.createUser({
    	    username: "admin",
            email: "qstn@stevexchen.com",
    	    password: "595commave",
            tier: 0
    	})
    };
});

Meteor.publish('Sessions', function(){
    return sessions.find({});
});

Meteor.publish('Comments', function(urlID){
    return comments.find({sessionId:urlID});
});

Meteor.publish('Users', function() {
    return Meteor.users.find({},{fields: {'username':1, 'emails':1 ,'tier':1}});
})

Meteor.methods ({
    deleteSession: function (sessionId) {
        comments.remove ({sessionId:sessionId})
    },
    toggleFilter: function (sessionId) {
        currentSession = sessions.findOne({sessionId:sessionId})
        currentSessionID = currentSession._id
        if (currentSession.filtering === false)
            sessions.update (currentSessionID, {$set:{filtering: true}})
        else 
            sessions.update (currentSessionID, {$set:{filtering: false}})
    },
    toggleTopics: function (sessionId) {
        currentSession = sessions.findOne({sessionId:sessionId})
        currentSessionID = currentSession._id
        if (currentSession.topics === false) 
            sessions.update (currentSessionID, {$set:{topics:true}})
        else 
            sessions.update (currentSessionID, {$set:{topics:false}})
    },
    toggleComments: function(sessionId) {
        currentSession = sessions.findOne({sessionId:sessionId})
        currentSessionID = currentSession._id
        if (currentSession.commenting === false)
            sessions.update (currentSessionID, {$set:{commenting: true}})
        else 
            sessions.update (currentSessionID, {$set:{commenting: false}})
    },
    incTier: function (userId) {
        Meteor.users.update (userId, {$inc: {tier:1}})
    },
    decTier: function (userId) {
        Meteor.users.update (userId, {$inc: {tier: -1}})
    }
})

Accounts.onCreateUser(function(options, user) {
  user.tier = 1;
  if (options.profile)
    user.profile = options.profile;
  return user;
});