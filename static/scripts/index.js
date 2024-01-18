async function cors_test(){
    const response = await fetch("http://alex.couch.co:3000", {
        method: "POST",
        mode: "cors",
        headers: {
            "Content-Type": "text/json",
        },
        body: JSON.stringify({ "name": "alex" })
    });
    return response.text();
}

cors_test().then((data)=>{
    console.log("CORS test success!");
    console.log(data);
})
.catch((err)=>{
    console.log("CORS test fail!");
    console.log(err);
});
