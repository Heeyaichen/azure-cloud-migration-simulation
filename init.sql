CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE
);

INSERT INTO users (name, email) VALUES
('Ibanez', 'ibanez@example.com'),
('Ernie Ball', 'ernieball@example.com'),
('Aristides', 'aristides@example.com');
