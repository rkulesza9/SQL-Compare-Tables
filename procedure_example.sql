declare @db1 varchar(100) = 'db_name';
declare @t1 varchar(100) = 'table1_name';
declare @pk1 varchar(100) = 'table 1 key to match (usually primary key)';
declare @db2 varchar(100) = 'db_name';
declare @t2 varchar(100) = 'table2_name';
declare @pk2 varchar(100) = 'table 2 key to match (usually primary key)';

exec compare_column_values @db1,@t1,@pk1,@db2,@t2,@pk2;
