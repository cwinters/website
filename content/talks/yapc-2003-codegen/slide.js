document.captureEvents(Event.KEYPRESS);

function alert_keycode(e)
{
  if ( e.which == 8 ) {
      location.href = document.getElementById( 'prevLink' ).href;
    }
  else if ( e.which == 32 ) {
    location.href = document.getElementById( 'nextLink' ).href;
  }
  else if ( e.which == 96 ) {
    location.href = document.getElementById( 'tocLink' ).href;
  }
}
document.onkeypress=alert_keycode
