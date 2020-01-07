import streams
import os
import endians
import strformat


type
    AssetEntry = object
        name: string
        dataOffset: uint32
        dataLength: uint32
        dataHash: uint32

    FlPack = object
        path: string
        name: string
        assets: seq[ref AssetEntry]


# Helper Functions
proc newAssetEntry(): ref AssetEntry =
    new(result)

proc readSwappedUint32(inStream: FileStream): uint32 =
    var a = inStream.readUint32
    swapEndian32(result.addr, a.addr)


# Main Functions
proc loadFlPack(path: string): ref FlPack =
    new(result)
    echo &"Loading '{path}'..."

    result.path = path
    result.name = splitFile(result.path).name

    let inStream = newFileStream(result.path, fmRead)
    if isNil(inStream): raise newException(IOError, &"'{path.absolutePath()}' doesn't exist")
    defer: inStream.close()

    var chunkCount = 0
    while true: # Loop until we run out of chunks
        echo &"\n### CHUNK {chunkCount}"
        let nextChunk = inStream.readSwappedUint32()
        let fileAmount = inStream.readSwappedUint32()

        echo &"# Next Chunk: {nextChunk:#010x}"
        echo &"# Assets: {fileAmount}"

        for _ in 0..<fileAmount:
            let asset = newAssetEntry()

            let nameLength = inStream.readSwappedUint32()
            asset.name = inStream.readStr(int(nameLength))
            # echo &"'{asset.name}'"

            asset.dataOffset = inStream.readSwappedUint32()
            asset.dataLength = inStream.readSwappedUint32()
            asset.dataHash = inStream.readSwappedUint32()

            result.assets.add(asset)
        
        if nextChunk == 0: break
        inc(chunkCount)
        inStream.setPosition(int(nextChunk))


when isMainModule:
    discard loadFlPack(r"sample.pack")