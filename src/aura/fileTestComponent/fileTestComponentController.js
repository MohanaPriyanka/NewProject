({ 
onDrop: function(component, event) { 
event.stopPropagation(); 
event.preventDefault(); 

var files = event.dataTransfer.files; 
for (var i=0; i<files.length; i=i+1) { 
var file = files[i]; 
var reader = new FileReader(); 
reader.onloadend = function(e) { 
console.log("loaded"); 
}; 
reader.readAsDataURL(file); 
} 
}, 

onDragOver: function(component, event) { 
event.preventDefault(); 
}, 
})