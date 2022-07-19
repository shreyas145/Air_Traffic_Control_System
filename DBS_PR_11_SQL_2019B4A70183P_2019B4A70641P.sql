create table aircraft_control(	-- creates table
flightID char(5) not null,
ETA time not null,
ETD time not null,
primary key(flightID)
);

insert into aircraft_control values('6D537', '20:40', '21:50'); -- inserts sample data
insert into aircraft_control values('6D538', '21:45', '22:00');

delimiter $$
create procedure view_table()	-- defines procedure to view all flights
begin
select * from aircraft_control;
end
$$ delimiter ;

delimiter $$
create procedure view_flight(in fid char(5))	-- defines procedure to view details of a flight
begin
select flightID,ETA,ETD from aircraft_control where flightID IN(fid);
end
$$ delimiter ;

delimiter $$
create procedure departure(in fid char(5))		-- defines procedure for handling departures
begin
delete from aircraft_control where aircraft_control.flightID = fid;
end $$
delimiter ;

delimiter $$
create procedure arrival(in fid char(5), in eta1 time, in etd1 time)	-- defines procedure for handling arrivals
begin
	declare maxcount int;
    declare a,d time;
    declare cura cursor for select ETA from aircraft_control;
	declare curb cursor for select ETD from aircraft_control;
    declare curcount cursor for select count(flightID) from aircraft_control;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET @status1 = 0;
    open cura;
    open curb;
    open curcount;
    set @count1 = 0;
    fetch curcount into maxcount;
    set @status1 = 0;
    loop1: loop
    fetch cura into a;
    fetch curb into d;
    if abs(time_to_sec(timediff(eta1,a))/60) < 5 or abs(time_to_sec(timediff(etd1,d))/60) < 5 then
		set @status1 = 1;
		leave loop1;
	end if;
	if @count1 >= maxcount then
		leave loop1;
    end if;
    set @count1 = @count1+1;
    end loop;
    if @status1 < 1 then
    insert into aircraft_control values(fid, eta1, etd1);
    end if;
    close cura;
    close curb;
end
$$ delimiter ;

start transaction;	-- sample query for insertion
lock table aircraft_control write;
call arrival('6F677', '23:30', '23:45');
unlock table;
commit;
start transaction;	-- views changes
lock table aircraft_control read;
call view_table();
unlock table;
commit;

start transaction;	-- sample query for insertion eta failure
lock table aircraft_control write;
call arrival('6F679', '20:40', '23:00');
unlock table;
commit;
start transaction;	-- views changes
lock table aircraft_control read;
call view_table();
unlock table;
commit;

start transaction;	-- sample query for insertion etd failure
lock table aircraft_control write;
call arrival('6F679', '21:30', '22:00');
unlock table;
commit;
start transaction;	-- views changes
lock table aircraft_control read;
call view_table();
unlock table;
commit;

start transaction;	-- sample query for departure
lock table aircraft_control write;
call departure('6F677');
unlock table;
commit;
start transaction;	-- views changes
lock table aircraft_control read;
call view_table();
unlock table;
commit;

start transaction;	-- sample query for flight details
lock table aircraft_control read;
call view_flight('6D538');
unlock table;
commit;

drop table aircraft_control;
drop procedure arrival;
drop procedure departure;
drop procedure view_table;
drop procedure view_flight;