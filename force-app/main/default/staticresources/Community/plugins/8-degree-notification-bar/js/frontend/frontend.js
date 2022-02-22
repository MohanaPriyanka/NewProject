(function ($) {
    $(function () {
        /* **** Slider Option **** */
        var duration = $('.notify_slider').data('slide-duration');
        var transition = $('.notify_slider').data('slide-transition');
        var controls =  $('.notify_slider').data('slide-controls');
        if(controls == 1){var control = true;}else{var control = false;}
        $('.notify_slider').bxSlider({
            auto: true,
			controls:control,
            pager:false,
            speed: duration,
            pause: transition,
            stopAuto: false,
        });// Slider Option End
        
        /* **** Ticker Option **** */
        var ticker_hover = $('.edn-ticker-slider').data('ticker-hover');
        //alert(ticker_hover);
        var ticker_speed = $('.edn-ticker-slider').data('ticker-speed');
        $('.edn-ticker').marquee({
        	speed: ticker_speed,
        	gap: 0,
        	delayBeforeStart: 0,
        	direction: 'left',
        	duplicated: true,
        	pauseOnHover: ticker_hover,
        });// Ticker Option End
        
        var valid = 1;
        $('#edn_subs_submit_ajax').click(function(e){
            e.preventDefault();
            var email = $('.edn-type-newsletter-wrap input[name="edn_email"]').val();
            var nonce = $('.edn-type-newsletter-wrap input[name="edn_subs_nonce_field"]').val();
            if(email == '')
            {
                valid = 0;
                $('.error').html('Email Address Required');
            }
            else
            {
                var emailReg = /^([\w-\.]+@([\w-]+\.)+[\w-]{2,4})?$/;
                if( !emailReg.test( email ) ) {
                    var valid_msg = $('#edn-msg').data('valid-msg');
                    $('.error').html(valid_msg);
                }else{
                    var success = $('#edn-msg').data('success');
                    var already = $('#edn-msg').data('aready-subs');
                    var check_to_conform = $('#edn-msg').data('check-conform');
                    //var ajaxurl = $('#edn-ajax-url').data('url');
                    $.ajax({
                        url: ajaxsubs.ajaxurl,
                        type: 'post',
                        dataType: 'html',
                        data: {
                            action:'ajax_subscribe',
                            email: email,
                            nonce: nonce,
                        },
                        beforeSend: function() {
                            $('#edn-loading').show('slow');
                        },
                        complete: function() {
                            $('#edn-loading').hide('slow');
                        },
                        success: function( resp ) {
                            //alert(resp);
                            if(resp == '0')
                            {
                                $('.error').html(already);
                            }else if(resp=='1'){
                                $('.error').html(check_to_conform);
                            }else{
                                $('.error').html(success);
                            }
                        }
                    });
                }  
            }          
        });//end subscribe submit by ajax
        
        /* Notification bar show and hide */
            $('.edn-top-up-arrow').click(function(){
                $(this).hide();
                $(this).next().show();
                $(this).parent().parent().prev().slideUp();
            });
            $('.edn-top-down-arrow').click(function(){
                $(this).hide();
                $(this).prev().show();
                $(this).parent().parent().prev().slideDown();
            });
            $('.edn-bottom-down-arrow').click(function(){
                $(this).hide();
                $(this).next().show();
                $(this).parent().parent().prev().slideUp();
            });
            $('.edn-bottom-up-arrow').click(function(){
                $(this).hide();
                $(this).prev().show();
                $(this).parent().parent().prev().slideDown();
            });//End of Notification bar show and hide 
        /* Notification bar Close */
        
        $('.edn-controls-close').click(function(){
            var vals = 'edn_close';
            $.ajax({
                url: ajaxsubs.ajaxurl,
                type: 'post',
                dataType: 'html',
                data: {
                    action:'ajax_close',
                    data: vals
                },
                beforeSend: function() {
                    $('#edn-close-load').show();
                },
                complete: function() {
                    $('#edn-close-load').hide();
                },
                success: function( res ) {
                    $('.edn_close_section').hide('slow');
                }
            });
        });
        
        
	});//$(function () end
}(jQuery));