ALTER TABLE `att`.`ent_entity` DROP KEY `type_rec_id`, ADD UNIQUE `type_rec_id` (`ent_com_id`, `ent_ety_id`, `ent_xxx_id`);

/* need to add searchForEntity and loadAttHistory procs after testing them

*/