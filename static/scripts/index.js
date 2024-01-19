async function cors_test(){
    const response = await fetch("http://alex.couch.co:3000/api/v1/user/5", {
        method: "POST",
        mode: "cors",
        headers: {
            "Content-Type": "text/json",
            "Access-Authentication-Test-Route": "test",
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
