variable "nodeclass_templatefile" {
  default = "nodeclass.tftpl"
}

variable "nodeclass_file" {
  default = "nodeclass.yaml"
}

variable "storage_templatefile" {
  default = "storage.tftpl"
}

variable "storage_file" {
  default = "storage.yaml"
}


resource "local_file" "nodeclass" {
  content = templatefile("${path.module}/${var.nodeclass_templatefile}",
    {
      cluster-name = module.eks.cluster_name
      tags = local.tags
    }
  )
  filename = var.nodeclass_file
  file_permission = "664"
}

resource "local_file" "storage" {
  content = templatefile("${path.module}/${var.storage_templatefile}",
    {
      tags = local.tags
    }
  )
  filename = var.storage_file
  file_permission = "664"
}
