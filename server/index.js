/* 

  

*/ 

var ip = require("ip");
console.dir ( ip.address() );

const express = require('express')
const app = express()

let macAddress = {
  "00:3e:e1:c1:fc:e7": "weather"
}

app.get('/', (req, res) => res.send('Hello World!'))


app.get('/image/:type', function (req, res) {
 // require('./screens/time')()

  let fileName = __dirname + '/output/time.png'

  

  res.sendFile(fileName, function (err) {
    console.log(fileName)
    console.log(req.params)
  })


  //res.send(req.params)
})


app.listen(3000, () => console.log('Example app listening on port 3000!'))



 let generate = () => {
//   require('./screens/weather')()
   require('./screens/time')()
}

 setInterval(generate, 5000)
 generate()

// console.log("sup")


