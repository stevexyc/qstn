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

    process.env.MAIL_URL = 'smtp://postmaster%40generalq.mailgun.org:5m2teynls-19@smtp.mailgun.org:587';

});

Meteor.publish('activeSession', function (urlID) {
    if(this.userId) {
        return sessions.find({});
    }
    else {
        return sessions.find({sessionId:urlID});
    }
})

Meteor.publish('Sessions', function(){
    return sessions.find({}, {fields: {'sessionId':1} });
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
    },
    deleteUser : function (userId) {
        Meteor.users.remove (userId)
    }
})

Accounts.config({
    sendVerificationEmail: true,
    forbidClientAccountCreation: false
});

Accounts.onCreateUser(function(options, user) {
  user.tier = 1;
  if (options.profile)
    user.profile = options.profile;
  return user;
});

Accounts.emailTemplates = {
  from: "General Q <no-reply@generalQ.com>",
  siteName: Meteor.absoluteUrl().replace(/^https?:\/\//, '').replace(/\/$/, ''),

  resetPassword: {
    subject: function(user) {
      return "Reset your General Q password" + Accounts.emailTemplates.siteName;
    },
    text: function(user, url) {
      var greeting = (user.profile && user.profile.name) ?
            ("Hello " + user.profile.name + ",") : "Hello,";
      return greeting + "\n"
        + "\n"
        + "To reset your password, simply click the link below.\n"
        + "\n"
        + url + "\n"
        + "\n"
        + "Thanks, General Q.\n";
    }
  },
  verifyEmail: {
    subject: function(user) {
      return "Welcome to General Q!";
    },
    text: function(user, url) {
      var greeting = (user.profile && user.profile.name) ?
            ("Hello " + user.profile.name + ",") : "Hello and Welcome to General Q!";
      return greeting + "\n"
        + "\n"
        + "Engage your audience by letting them ask questions and vote on the best ones!\n"
        + "\n"
        + "To reference the documentation go to docs.generalq.com\n" 
        + "\n"
        + "Feel free to email us at hello@generalq.com\n"
        + "\n"
        // + url + "\n"
        + "\n"
        + "Thanks, General Q.\n"
        + "www.generalq.com\n";
    }
  },
  enrollAccount: {
    subject: function(user) {
      return "An account has been created for you on " + Accounts.emailTemplates.siteName;
    },
    text: function(user, url) {
      var greeting = (user.profile && user.profile.name) ?
            ("Hello " + user.profile.name + ",") : "Hello,";
      return greeting + "\n"
        + "\n"
        + "To start using the service, simply click the link below.\n"
        + "\n"
        + url + "\n"
        + "\n"
        + "Thanks.\n";
    }
  }
};