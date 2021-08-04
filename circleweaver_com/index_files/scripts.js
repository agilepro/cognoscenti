/* global jQuery */
jQuery( document ).ready( function () {
	'use strict';
	jQuery( '.pirate-forms-file-upload-button' ).on( 'click', function () {
		var $button = jQuery( this );
		$button.parent().find( 'input[type=file]' ).on( 'change', function () {
			$button.parent().find( 'input[type=text]' ).val( jQuery( this ).val() ).change();
		} );
		$button.parent().find( 'input[type=file]' ).focus().click();
	} );

	jQuery( '.pirate-forms-file-upload-input' ).on( 'click', function () {
		jQuery( this ).parent().find( '.pirate-forms-file-upload-button' ).trigger( 'click' );
	} );
	jQuery( '.pirate-forms-file-upload-input' ).on( 'focus', function () {
		jQuery( this ).blur();
	} );
} );

jQuery( window ).load( function () {
	'use strict';
	if ( jQuery( '.pirate_forms_wrap' ).length ) {
		jQuery( '.pirate_forms_wrap' ).each( function () {
			var formWidth = jQuery( this ).innerWidth();
			var footerWidth = jQuery( this ).find( '.pirate-forms-footer' ).innerWidth();
			if ( footerWidth > formWidth ) {
				jQuery( this ).find( '.contact_submit_wrap, .form_captcha_wrap, .pirateform_wrap_classes_spam_wrap' ).css( {'text-align' : 'left', 'display' : 'block' } );
			}
		} );
	}
} );