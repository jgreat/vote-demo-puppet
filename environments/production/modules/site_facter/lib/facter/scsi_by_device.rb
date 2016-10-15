# scsi_by_device.rb
Facter.add(:scsi_by_device) do
  setcode do
    scsi_hash = {}
    Facter.value(:disks).each do |disk, value|
      if disk =~ /^sd/
        # lrwxrwxrwx 1 root root 0 Sep 27 14:19 /sys/block/sda/device -> ../../../2:0:0:0
        ls = Facter::Core::Execution.exec("/bin/ls -l /sys/block/#{disk}/device").rstrip
        # ../../../2:0:0:0
        dev = ls.split(/\s+/).last
        # 2:0:0:0
        scsi = dev.split(/\//).last
        controller, channel, id, lun = scsi.split(/:/)
        scsi_hash[disk] = {
          :controller => controller,
          :channel => channel,
          :id => id,
          :lun => lun
        }
      end
    end
    scsi_hash
  end
end
