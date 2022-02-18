({
	initializeLiveAgent : function(component, event, helper) {
		liveagent.init('https://d.la2w2.salesforceliveagent.com/chat', '572j0000000L8TH', '00Dj0000001q7GO');
        if (!window._laq) { window._laq = []; }
		window._laq.push(function(){
            liveagent.showWhenOnline('573j0000000LA5U', document.getElementById('liveagent_button_online_573j0000000LA5U'));
			liveagent.showWhenOffline('573j0000000LA5U', document.getElementById('liveagent_button_online_573j0000000LA5U'));
		});
	}
})