function Process-Address {
    param(
        [Parameter(Mandatory=$true)][String]$rawString,
        [Parameter(Mandatory=$false)][String]$mappingTablePath="C:\Users\jvbak\Documents\Assignments\OR 568\Project\tokenMappings.tsv"
    )

    $processedString = ""

    # Two kinds of processing - Token replacement and token stripping.
    $mappingTable = [Ordered]@{}
    $particleTable = [System.Collections.ArrayList]@()
    
    # Import the mapping table
    foreach ($elem in $(Import-Csv $mappingTablePath -Delimiter "`t") ) {
        switch ($elem.ACTION) {
            ("MAP") {
                $mappingTable[$elem.RAWSTRING] = $elem.MAPPING.replace("\NA","")
            }
            ("STRIP") {
                [Void]$particleTable.add($elem.RAWSTRING)
            }
        }
    }

    $containsComma = $rawString.Contains(",")

    # Remove trailing information after the comma
    if ($containsComma) {
        $rawString = $rawString.Split(",")[0]
    }

    if ($rawstring.split(" ").Count -eq 1) {
        return $rawString
    }

    # Remove the first element if it's parseable into a number.
    if ([Int32]$rawString.split(" ")[0].replace("-","")) {
        $rawString = $rawString.replace( $rawString.split(" ")[0], "").trim()
    }

    foreach ($token in $rawString.split(" ") ) {

        if ($token.trim() -eq "") {
            continue
        }

        if ($mappingTable.contains($token)) {

            # This is a special case where the positioning of the "ST" abbreviation can make a huge
            # difference on what the word means; typically, "STREET" won't be the first word within the 
            # string, and it's a safe bet to use "SAINT" versus "STREET" here.
            if ($token.contains("ST")) {
                switch ($rawString.Split(" ").indexOf($token)) {
                    (0) {
                        $processedString += "{0} " -f ("SAINT") 
                    }
                    default {
                        $processedString += "{0} " -f ($mappingTable[$token])
                    }
                }
            }
            else {
                $processedString += "{0} " -f ($mappingTable[$token])
            }
        }
        else {
            $processedString += "{0} " -f ($token.trim())
        }
 
    }


    return $processedString
    
}


$filePath = "C:\Users\jvbak\Documents\Assignments\OR 568\Project\nyc-rolling-sales-latlong-trans.csv"

$data = Import-Csv -Path $filePath

$newArray = [System.Collections.Arraylist]::new($data.Count)

foreach ($rowElem in $data) {
    
    $newArray.add(
        $(Process-Address -rawString $rowElem.ADDRESS)
    )
    

}

$resultsPath = "C:\Users\jvbak\Documents\Assignments\OR 568\Project\address_split.csv"

$newArray -join "`n" | Out-File $resultsPath -Force
