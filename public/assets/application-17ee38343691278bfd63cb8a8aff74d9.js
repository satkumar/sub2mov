$(document).ready(function(){$(".blink").focus(function(){this.title==this.value&&(this.value="")}).blur(function(){this.value==""&&(this.value=this.title)}),$("#pop-carousel").CloudCarousel({reflHeight:56,reflGap:2,xPos:285,yPos:120,altBox:$("#alt-text"),titleBox:$("#title-text"),buttonLeft:$("#left-but"),buttonRight:$("#right-but"),yRadius:40,speed:.15,mouseWheel:!0,autoRotate:"left",autoRotateDelay:3600,bringtoFront:!0}),$("#filter").click(function(){return $("#genres").toggle(400),!1})});