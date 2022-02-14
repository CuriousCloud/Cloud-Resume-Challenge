async function fetchCount() {
  try {
    const response = await fetch('https://9q0daknm1d.execute-api.us-east-1.amazonaws.com/prod');
    const count = await response.json();
    return count;
  } catch (err) {
    console.log("That didn't work");
  }
}
fetchCount()
  .then(count => {
    console.log(count);
    document.getElementById('count').innerHTML = count;
  })
