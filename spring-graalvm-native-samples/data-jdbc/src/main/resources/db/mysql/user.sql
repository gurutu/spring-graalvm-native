CREATE DATABASE IF NOT EXISTS dataJDBC;
CREATE USER 'dataJDBC' IDENTIFIED BY 'dataJDBC';
ALTER DATABASE dataJDBC DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
GRANT ALL PRIVILEGES ON dataJDBC.* TO 'dataJDBC'@'%';
