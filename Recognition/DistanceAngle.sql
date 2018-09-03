create database if not exists dbcoba;

use dbcoba;

create table if not exists signature (
sigID varchar(300) not null unique primary key,
objectType varchar(50) not null
) engine=InnoDB default charset=latin1;

-- select * from signature ;
-- delete from signature;

-- insert into signature   values ("abc", "cde");