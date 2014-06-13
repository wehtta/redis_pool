

function a(){  
 console.log(arguments);  
 return function(){  
  console.log(arguments);  
 };  
};  

a("string")