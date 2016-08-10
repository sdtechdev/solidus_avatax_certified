showTime = 5000
fadeOutTime = 500

Spree.ready ($) ->
  # Make flash messages dissapear
  # We only want to target the flash messages which are initially on the page.
  # Otherwise we risk hiding messages added by show_flash
  $initialFlash = $(".flash")
  setTimeout (->
    $initialFlash.fadeOut(fadeOutTime)
  ), showTime

window.show_flash = (type, message) ->
  $flashWrapper = $(".js-flash-wrapper")
  if $flashWrapper.length == 0
    $('.address_validator').before("<div class=\"js-flash-wrapper\" />")
  $flashWrapper.empty()
  flash_div = $("<div class=\"flash #{type}\" />")
  $flashWrapper.prepend(flash_div)
  flash_div.html(message).show().delay(showTime).fadeOut(fadeOutTime)
