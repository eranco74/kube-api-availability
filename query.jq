. as $root 
| .[0] as $apiserver_group
| $apiserver_group.data as $existing_records
| $existing_records[-1] as $last_record
| [
    {
        "group": "apiserver",
        "data": (
            if $current_status == $last_record.data[0].val then
            (
                $existing_records[:-1] + [
                    {
                        "label": "kube-apiserver",
                        "data": [
                            {
                                "timeRange": [
                                    $last_record.data[0].timeRange[0],
                                    (now | todateiso8601)
                                ],
                                "val": $current_status
                            }
                        ]
                    }
                ]
            ) else (
                $existing_records + [
                    {
                        "label": "kube-apiserver",
                        "data": [
                            {
                                "timeRange": [
                                    ($last_record.data[0].timeRange[1] // (now | todateiso8601)),
                                    (now | todateiso8601)
                                ],
                                "val": $current_status
                            }
                        ]
                    }
                ]
            )
            end
        )
    }
]
