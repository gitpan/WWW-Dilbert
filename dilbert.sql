CREATE TABLE dilbert_character (
        id int unsigned not null primary key auto_increment,
        name char(100) not null,
        regular_character bool default null,
        notes text,
        photo_blob blob
);

INSERT INTO dilbert_character VALUES (NULL,'Dilbert',1,"Dilbert loves technology for the sake of technology. In fact, Dilbert loves technology more than people. He's got the social skills of a mousepad and he'd rather surf the Internet than Waikiki (which, considering the physique he developed after years of sitting in front of a PC screen, is a blessing).",NULL);
INSERT INTO dilbert_character VALUES (NULL,'Dogbert',1,"Genetically he may be a dog, but Dogbert is no man's best friend. He treats people with disdain, reserving special contempt for Dilbert, who's no master--or match--for Dogbert. (Although he wouldn't admit it, if push came to shove, he'd protect the bumbler. And never let him forget it). His not-so-secret ambition is to conquer the world and enslave all humans. He anointed himself St. Dogbert, and as such takes special delight in exorcising the demons of stupidity.",NULL);
INSERT INTO dilbert_character VALUES (NULL,'The Boss',1,"He's every employee's worst nightmare. He wasn't born mean and unscrupulous, he worked hard at it. And succeeded. As for stupidity, well, some things are inborn. His top priorities are the bottom line and looking good in front of his subordinates and superiors (not necessarily in that order). Of absolutely no concern to him is the professional or personal well-being of his employees. The Boss is technologically challenged but he stays current on all the latest business trends, even though he rarely understands them.",NULL);
INSERT INTO dilbert_character VALUES (NULL,'Wally',1,"Dilbert's colleague and fellow engineer is a thoroughly cynical employee who has no sense of company loyalty and feels no need to mask his poor performance or his total lack of respect.",NULL);
INSERT INTO dilbert_character VALUES (NULL,'Alice',1,"Alice is the only female engineer in Dilbert's department. She's habitually overworked. Her cardiovascular system is basically coffee. She has a quick temper when confronted with the idiocy of her co-workers. She does not handle criticism well.",NULL);
INSERT INTO dilbert_character VALUES (NULL,'Asok the Intern',1,"Asok, pronounced ah-shook, was introduced to satisfy the hordes of interns who wrote to request their own character. Asok is brilliant, but as an intern he is immensely naive about the cruelties and politics of the business world. His name is a common one in India (but usually spelled Ashok).",NULL);
INSERT INTO dilbert_character VALUES (NULL,'Catbert',1,"Catbert is a typical cat, in the sense that he looks cute but he doesn't care if you live or die. As Human Resources Director at Dilbert's company, he teases employees before downsizing them.",NULL);
INSERT INTO dilbert_character VALUES (NULL,'Ratbert',1,"Ratbert is a simpleminded optimist. He wants nothing more than to be loved, but he's doomed to ratdom which, despite his cheerfulness, makes him an unlikely candidate for affection. His resiliency enables him to continually be the butt of everyone's jokes.",NULL);
 
CREATE TABLE dilbert_strip (
        id bigint(14) unsigned not null primary key,
        strip_blob mediumblob not null,
        bytes int unsigned not null,
        width int(4) unsigned not null,
        height int(4) unsigned not null,
        colour bool default null,
        cells enum('3','6','-1') default "3" not null,
        text text
);
 
CREATE TABLE dilbert_character2dilbert_strip (
        dilbert_character_id int unsigned not null,
        dilbert_strip_id bigint(14) unsigned not null,
        primary key (dilbert_character_id, dilbert_strip_id)
);

