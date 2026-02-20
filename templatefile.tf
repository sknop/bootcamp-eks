variable "nodeclass_templatefile" {
  default = "nodeclass.tftpl"
}

variable "inventory_file" {
  default = "nodeclass.yaml"
}

resource "local_file" "nodeclass" {
  content = templatefile("${path.module}/${var.nodeclass_templatefile}",
    {
      cluster-name = module.eks.cluster_name
      tags = local.tags
    }
  )
  filename = var.inventory_file
  file_permission = "664"
}
