'use strict';

// returns the value of `num1`
console.log("ARgumentos")
console.log(process.argv);

var myArgs = process.argv.slice(2);
console.log('myArgs: ', myArgs);

const fs = require('fs');
const carbone = require('carbone');

let rawdata = fs.readFileSync(myArgs+'/doc/reqs.json');  
let data = JSON.parse(rawdata);

  carbone.render(myArgs+'/templates/reqs_template.odt', data, function(err, result){
    if (err) return console.log(err);
    fs.writeFileSync(myArgs+'/doc/reqs_report.odt', result);
  });

  carbone.render(myArgs+'/templates/reqs_template.ods', data, function(err, result){
    if (err) return console.log(err);
    fs.writeFileSync(myArgs+'/doc/reqs_report.ods', result);
  });


