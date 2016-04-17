#/bin/bash
path=/tmp/backups_jorge
#Modificar por el path del SAN u otra ruta de destino de las descargas
cd $path
bk_date=`date "+%Y-%m-%d"`
if [ -d "./$bk_date" ];
then
	echo "La carpeta de backup ya existe, procediendo a borrado"
	rm -rf $bk_date
fi
echo "Creando carpeta de backup $bk_date"
mkdir $bk_date
cd $bk_date

for vm_uuid in `xe vm-list is-control-domain=false is-a-snapshot=false | awk '{if($1=="uuid") print $5}'`;
do
	vm_name=`xe vm-list uuid=$vm_uuid | awk '{if($1=="name-label") print $4}'`
	vm_snap_uuid=`xe vm-snapshot vm=$vm_uuid new-name-label="$vm_name"_"$bk_date"`
	xe template-param-set is-a-template=false ha-always-run=false uuid=$vm_snap_uuid
	xe vm-export vm=$vm_snap_uuid filename="$vm_name"_"$bk_date".xva
	xe vm-uninstall uuid=$vm_snap_uuid force=true
done

cd ..
num_backups=`ls -l | sed '1d' | wc -l`
bk_rotate=7
if [ $num_backups -gt $bk_rotate ];
then
	dir_delete=`ls -lt | tail -n 1 | awk '{print $9}'`
	echo "borrando $dir_delete por rotacion de backups"
	rm -rf $dir_delete
fi