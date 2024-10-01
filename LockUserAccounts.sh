version: 0.1
component: command
timeoutInSeconds: 6000
env: 
  variables: 
    l_tns_alias: ${tns_alias}
    l_password: ${password}
    l_adw_ocid: ${adw_ocid}
shell: bash

steps:
  - type: Command
    timeoutInSeconds: 600
    name: "Lock User Accounts"
    command: |
      echo "define tns_alias=${l_tns_alias}" > vars.sql
      echo "define password=${l_password}" >> vars.sql
      oci db autonomous-database generate-wallet --autonomous-database-id ${l_adw_ocid} --file wallet.zip --password Oracle123
      sql /nolog @/workspace/vars
      whenever sqlerror exit sqlcode
      set cloudconfig wallet.zip
      connect admin/&password@&tns_alias
      begin
        for u in (
                  select u1.username
                  from dba_users u1
                  where u1.username not in (select u2.username from adw_default_users u2)
                 ) loop
          execute immediate 'alter user '||u.username||' account lock';
        end loop;
      end;
      /
      exit
    onFailure:
      - type: Command
        command: |
          echo "Failed!"
        timeoutInSeconds: 60
