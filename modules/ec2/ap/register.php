<?php
  $username = $_POST['username'];
  $password = $_POST['password'];

  $host = 'mysql';  // Can use swarm service name.
  $user = 'root';
  $pass = 'Dev12876266';
  $db = 'test';

  $conn = mysqli_connect($host, $user, $pass, $db);

  if (!$conn) {
    die("Connection failed: " . mysqli_connect_error());
  }

  $sql = "INSERT INTO adduser (username, password) VALUES ('$username', '$password')";

  if (mysqli_query($conn, $sql)) {
    echo "New user created successfully";
  } else {
    echo "Error: " . $sql . "<br>" . mysqli_error($conn);
  }

  mysqli_close($conn);

  header("Location: http://52.199.154.209"); // Internet access.
  exit;
?>