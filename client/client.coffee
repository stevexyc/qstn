loadFirst = Meteor.subscribe("Sessions")
Meteor.subscribe("Users")
Meteor.autosubscribe ->
	Meteor.subscribe "activeSession", Session.get("urlID")
	Meteor.subscribe "Comments", Session.get("urlID")

sessions = new Meteor.Collection('Sessions')
comments = new Meteor.Collection('Comments')

Meteor.startup ->
	cookies = document.cookie.split(';')
	for x in cookies
		names = x.split('=')
		value = names[0].trim()
		upvotes.push value

	Deps.autorun ->
		if not Session.equals 'urlID', null
			currentSession = sessions.findOne({sessionId:Session.get('urlID')})
			enableComments = currentSession.commenting
			enableFilter = currentSession.filtering
			enableTopics = currentSession.topics
			Session.set 'enableTopics', enableTopics
			Session.set 'enableComments', enableComments
			Session.set 'enableFilter', enableFilter

Session.set 'showing', 'popular'
Session.set 'questionEdit', null
Session.set 'showModal', 'hide'
Session.set 'urlID', null
Session.set 'tagfilter', null

upvotes = []

# pagecontrol
Template.pagecontrol.loadFirst = ->
	true if loadFirst.ready() is false

Template.pagecontrol.idInURL = ->
	page_index = window.location.pathname
	if page_index.charAt(0) is '/'
		urlID = page_index.substring(1, page_index.length).trim().toUpperCase()
		if sessions.findOne({sessionId:urlID}) isnt undefined
			Session.set 'urlID', urlID
			true

# Template.pagecontrol.events {
# 	'click #test': (e,t) ->
# 		tags = []
# 		if Session.get('tagfilter') isnt (null or undefined)
# 			console.log Session.get 'tagfilter'
# 		else 
# 			console.log 'WOOOOOOWEEE'	
# }

# StartPage	
Template.app.mobile = ->
	/Android|webOS|iPhone|iPad|iPod|BlackBerry/i.test(navigator.userAgent)

Template.app.yourSession = ->
	id = Meteor.userId()
	if adminOnly(id)
		sessions.find {}
	else
		sessions.find({owner:id})

Template.app.adminOnly = ->
	if Meteor.userId()
		adminOnly Meteor.userId()

Template.app.allUsers = ->
	Meteor.users.find({})

Template.app.ownerUsrname = ->
	Meteor.users.findOne(this.owner).username

Template.app.events {
	'click #gotofeatures': (e,t) ->
		$('html, body').animate({scrollTop:$('#features').position().top}, 'slow')

	'click #joinSession': (e,t)->
		joinSession(e,t)

	'keyup #joinSessionId': (e,t) ->
		if e.which is 13
			joinSession(e,t)		

	'click #createSession': (e,t) ->
		title = document.getElementById('sessionTitle').value.trim()
		user = Meteor.users.findOne(Meteor.userId())
		optnlID = document.getElementById('optionalID').value.trim().toUpperCase()
		if title.length is 0
			document.getElementById('error').innerHTML = 'need title name'
		# else if user.emails[0].verified is false 
		# 	document.getElementById('error').innerHTML = 'please verify your email'
		else if (user.tier is 1) and (sessions.find({owner:Meteor.userId()}).count() is 3)
			document.getElementById('error').innerHTML = 'upgrade to create more sessions'
		else if sessions.findOne({sessionId:optnlID}) isnt undefined
			document.getElementById('error').innerHTML = 'Passcode Taken, choose another'
		else 
			if optnlID.length is 0
				sessionId = makeId()
			else 
				sessionId = optnlID
			userId = Meteor.userId()
			sessions.insert {
				title: title
				sessionId: sessionId
				owner: userId
				filtering: false
				topics: false
				tags:[]
				commenting: false
			}
			document.getElementById('sessionTitle').value = ''
			document.getElementById('optionalID').value = ''
			document.getElementById('success').innerHTML = 'successfully created ' + title

	'click .deleteSession': (e,t) ->
		sessions.remove this._id
		Meteor.call 'deleteSession', this.sessionId

	'click .inc': (e,t) ->
		if adminOnly Meteor.userId() 
			Meteor.call('incTier', this._id)

	'click .dec': (e,t) ->
		if adminOnly Meteor.userId() 
			Meteor.call('decTier', this._id)
}

# QuesionList
Template.list.sessionTitle = ->
	sessions.findOne({sessionId: Session.get('urlID')}).title

Template.list.topics = ->
	sessions.findOne({sessionId: Session.get('urlID')}).tags

Template.list.newTopic = ->
	Session.equals 'newTopic', true

Template.list.item = ->
	if not Session.equals 'tagfilter', null
		tagFilter = Session.get 'tagfilter'
	if adminOrMod Meteor.userId()
		sel = {}
	else if Session.equals 'enableFilter', true
		sel = {approved:true}
	else
		sel = {}
	sel.tags = tagFilter if tagFilter

	if Session.equals 'showing', 'recent'
		comments.find sel, {sort: {answered:1, time:-1}}
	else if Session.equals 'showing', 'popular'
		comments.find sel, {sort: {answered:1, votes:-1, time: 1}}
	else 
		comments.find sel, {sort: {time:-1}}

Template.list.popular = ->
	if Session.equals 'showing', 'popular'
		'active'

Template.list.recent = ->
	if Session.equals 'showing', 'recent'
		'active'

Template.list.FilterOption = ->
	if Session.equals 'enableFilter', false
		'Enable Filters'
	else 'Disable Filters'

Template.list.TopicsOption = ->
	if Session.equals 'enableTopics', false
		'Enable Topics'
	else 'Disable Topics'

Template.list.CommentOption = ->
	if Session.equals 'enableComments', false
		'Enable Comments'
	else 'Disable Comments'

Template.list.filterEnabled = ->
	Session.equals 'enableFilter', true

Template.list.topicsEnabled = ->
	Session.equals 'enableTopics', true

Template.list.commentsEnabled = ->
	Session.equals 'enableComments', true

Template.list.qstnApproved = ->
	this.approved is false

Template.list.defaultTag = ->
	if Session.equals 'tagfilter', null
		'active'

Template.list.activeTag = ->
	if Session.equals 'tagfilter', this.toString()
		'active'

Template.list.ifchecked = ->
	if this._id in upvotes
		'checked'

Template.list.editing = ->
	Session.equals 'questionEdit', this._id

Template.list.moderator = ->
	if Meteor.user()?
		adminOrMod Meteor.userId()

Template.list.adminOnly = ->
	if Meteor.user()?
		adminOnly Meteor.userId()

Template.list.answered = ->
	this.answered is true

Template.list.addingtag = ->
	Session.equals 'addingtag', this._id

Template.list.commentCount = ->
	this.comments.length

Template.list.placeholder = ->
	if Session.get('tagfilter') is null
		'submit new question'
	else 
		'submit new question to ' + Session.get('tagfilter')

Template.list.tier2 = ->
	if Meteor.userId()?
		user = Meteor.users.findOne(Meteor.userId())
		if user.tier >= 1
			true
		else false

Template.list.tier3 = ->
	if Meteor.userId()?
		user = Meteor.users.findOne(Meteor.userId())
		if user.tier >= 1
			true
		else false

Template.list.events {
	'click #submitquestion': (e,t) ->
		Ask(e,t)

	'focusin #inputquestion': (e,t) ->
		if /Android|webOS|iPhone|iPad|iPod|BlackBerry/i.test(navigator.userAgent)
			$('#eraseMe').css('height','0px')
			$('#submitbox').css('position','relative')
			$("html,body").scrollTop('42px');

	'focusout #inputquestion':(e,t) ->
		if /Android|webOS|iPhone|iPad|iPod|BlackBerry/i.test(navigator.userAgent)
			$('#eraseMe').css('height','42px')
			$('#submitbox').css('position','fixed')

	'keyup #inputquestion': (e,t) ->
		if e.which is 13
			Ask(e,t)

	'click .upvote': (e,t)->
		if this._id not in upvotes
			comments.update this._id, {$inc: {votes: 1 }}
			upvote(this._id)
		else 
			comments.update this._id, {$inc: {votes: -1}}
			downvote(this._id)

	'click #showPopular': (e,t) ->
		Session.set 'showing', 'popular'

	'click #showRecent': (e,t) ->
		Session.set 'showing', 'recent'

	'click #enableFilter': (e,t) ->
		Meteor.call 'toggleFilter', Session.get 'urlID'

	'click #enableTopics': (e,t) ->
		Meteor.call 'toggleTopics', Session.get 'urlID'

	'click #enableComments': (e,t) ->
		Meteor.call 'toggleComments', Session.get 'urlID'

	'click #newTopic': (e,t) ->
		Session.set 'newTopic', true
		Deps.flush()
		focusText t.find '#newtopicname'

	'keyup #newtopicname': (e,t) ->
		if e.which is 13
			if e.target.value.trim().length is 0
				Session.set 'newTopic', false
			else
				currentSession = sessions.findOne({sessionId:Session.get('urlID')})
				sessions.update( currentSession._id, {$addToSet: {tags: e.target.value.trim()}})
				Session.set 'newTopic', false

	'click .deleteTopic': (e,t) ->
		currentSession = sessions.findOne({sessionId:Session.get('urlID')})
		sessions.update( currentSession._id, {$pull: {tags: this.toString()}})
		Deps.flush()
		if Session.equals 'tagfilter', this.toString()
			Session.set 'tagfilter', null

	'focusout #newtopicname': (e,t) ->
		Session.set 'newTopic', false

	'click .approveQstn': (e,t) ->
		comments.update this._id, {$set: {approved: true}}

	'click .default': (e,t) ->
		Session.set 'tagfilter', null

	'click .menutag': (e,t) ->
		Session.set 'tagfilter', this.toString()

	'dblclick .questionText': (e,t) ->
		if Meteor.user()? and adminOrMod Meteor.userId()
			Session.set 'questionEdit', this._id
			Deps.flush()
			focusText t.find('#questionEdit')

	'keyup #questionEdit': (e,t) ->
		if e.which is 13
			newquestion = e.target.value
			comments.update this._id, {$set: {question: newquestion}}
			Session.set 'questionEdit', null

	'focusout #questionEdit': (e,t) ->
		Session.set 'questionEdit', null

	'click .answered':(e,t) ->
		if this.answered is false
			comments.update this._id, {$set: {answered: true}} 
		else
			comments.update this._id, {$set: {answered: false}}

	'click .addtag':(e,t) ->
		Session.set 'addingtag', this._id
		Deps.flush()
		focusText t.find('#addtag')

	'keyup #addtag': (e,t) ->
		if e.which is 13
			newtags = e.target.value.split(',')
			comments.update this._id, {$set: {tags: newtags}}
			Session.set 'addingtag', null

	'focusout #addtag': (e,t) ->
		Session.set 'addingtag', null

	'click .delete': (e,t) ->
		console.log 'delete'
		comments.remove this._id

	'click #export': (e,t) ->
		JSON2CSV()
		
	'dblclick #clear': (e,t)->
		removeAll() 

	'click .showComments': (e,t) ->
		Session.set 'showModal', 'show'
		Session.set 'commentID', this._id
}

Template.commentModal.HideModal = ->
	Session.get 'showModal'

Template.commentModal.Header = ->
	id = Session.get 'commentID'
	comments.findOne(id)

Template.commentModal.moderator = ->
	if Meteor.user()?
		adminOrMod Meteor.userId()

Template.commentModal.events {
	'click .hideComment': (e,t) ->
		Session.set 'showModal', 'hide'

	'click #addComment': (e,t) ->
		id = Session.get 'commentID'
		Comment(e,t,id)

	'keyup #inputcomment': (e,t) ->
		if e.which is 13
			id = Session.get 'commentID'
			Comment(e,t,id)

	'click .deletecomment': (e,t) ->
		cmt = this.toString()
		id = Session.get 'commentID'
		comments.update id, {$pull: {comments: cmt}}
}

Template.list.preserve {
	'input.add'
	'#tagmenu'
}

# Config
Accounts.ui.config({
     passwordSignupFields: 'USERNAME_AND_EMAIL'
});

Array::remove = (e) -> @[t..t] = [] if (t = @indexOf(e)) > -1

# Functions
go2Main = ()-> 
	page_index = window.location.pathname
	if page_index.charAt(0) is '/'
		urlID = page_index.substring(1, page_index.length).trim().toUpperCase()
		if sessions.findOne({sessionId:urlID}) is undefined
			window.location.pathname = '/'

JSON2CSV = () ->
    json = comments.find {sessionId: Session.get('urlID')}, {sort: {votes: -1}}
    str = 'Votes, Question, Topic, Answered \r\n'
    json.forEach (Item) ->
        str += Item.votes + ',' + Item.question.replace(/,/g, '') + ',' + Item.tags.toString().replace(/,/g, ' ') + ',' + Item.answered + '\r\n'
    window.open("data:text/csv;charset=utf-8," + escape(str))

makeId = ->
    text = ""
    possible = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    i = 0
    while i < 4
        text += possible.charAt(Math.floor(Math.random() * possible.length))
        i++
    if text in ['DAMN','SHIT','CRAP','FUCK','FACK','FOCK','FURY','ASSH','ASSE','SHAT','SHUT','DICK','DACK','MACK','NIGS','NIGA','MOFO','DUNG','CHNK','KINK','FAGS','AFAG','FUKU','SEXY','ASEX','SEXI','XXXX','SEXX']
    	makeId()
    else if sessions.findOne({sessionId:text}) is undefined
    	text
    else 
    	makeId()

joinSession = (e,t) ->
	sessionId = document.getElementById('joinSessionId').value.trim().toUpperCase()
	if sessionId.length is 0
		false
	else if sessions.findOne({sessionId:sessionId}) is undefined
		document.getElementById('error1').innerHTML = 'No Session Found'
		false
	else 
		Session.set 'urlID', sessionId
		window.location.pathname = '/' + sessionId

removeAll = () ->
    all = comments.find {} 
    ids = []
    all.forEach (Item) ->
        ids.push Item._id
    for x in ids
        comments.remove {_id:x}

upvote = (id) ->
    upvotes.push id
    createCookie id,id,1

downvote = (id) ->
    upvotes.remove id
    eraseCookie(id)

createCookie = (name, value, days) ->
  if days
    date = new Date()
    date.setTime date.getTime() + (days * 24 * 60 * 60 * 1000)
    expires = "; expires=" + date.toGMTString()
  else
    expires = ""
  document.cookie = name + "=" + value + expires + "; path=/"

eraseCookie = (name) ->
  createCookie name, "", -1

Ask = (e,t)->
    newquestion = document.getElementById('inputquestion').value.trim()
    tags = []
    if Session.get('tagfilter') isnt null
    	tags.push Session.get('tagfilter')
    if newquestion.length is 0
        console.log 'nothing to submit'
    else
        comments.insert {
            question: newquestion
            time: Date.now()
            answered: false
            tags: tags
            votes: 0
            comments: []
            sessionId: Session.get('urlID')
            approved: false
        }
        Deps.flush()
        $("html,body").scrollTop($(document).height());
        document.getElementById('inputquestion').value = ''

Comment = (e,t,id) ->
    newcomment = document.getElementById('inputcomment').value.trim()
    if newcomment.length is 0
        console.log 'no Comment'
    else 
        comments.update {_id:id}, {$push:{comments: newcomment}}
        document.getElementById('inputcomment').value = ''

adminOrMod = (userId) ->
	sessionId = Session.get 'urlID'
	tmp = sessions.findOne({sessionId:sessionId})
	Admin = Meteor.users.findOne({username:"admin"})
	userId is Admin._id or userId is tmp.owner

adminOnly = (userId) ->
	Admin = Meteor.users.findOne({username:"admin"})
	if Admin?
		userId is Admin._id
		
focusText = (i)->
    i.focus()
    i.select()
