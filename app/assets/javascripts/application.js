$(document).ready(function(){
  $(".blink").focus(function() {
    if(this.title==this.value) {
      this.value = '';
    }
  })
      
  .blur(function(){
    if(this.value=='') {
      this.value = this.title;                    
    }
  });

  $("#pop-carousel").CloudCarousel(   
    {     
      reflHeight: 56,
      reflGap:2,
      xPos: 285,
      yPos: 120,
      altBox: $("#alt-text"),
      titleBox: $("#title-text"),
      buttonLeft: $('#left-but'),
      buttonRight: $('#right-but'),
      yRadius:40,
      speed:0.15,
      mouseWheel:true,
      autoRotate: 'left',
      autoRotateDelay: 3600,
      bringtoFront: true
    });

    $('#filter').click(function() {
      $('#genres').toggle(400);
      return false;
    });

});
