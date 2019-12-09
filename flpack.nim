import streams
import os
import endians
import strformat

type
    ChunkHeader = object
        nextChunk: uint32
        fileAmount: uint32

    AssetHeader = object
        nameLength: uint32
        assetName: string
        assetoffset: uint32
        dataLength: uint32
        checksum: uint32

    FlPackChunk = object
        header: ChunkHeader
        assets: seq[AssetHeader]
    
    FlPack = object
        path: string
        name: string
        chunks: seq[FlPackChunk]


proc readSwappedUint32(inStream: FileStream): uint32 =
    var a = inStream.readUint32
    swapEndian32(result.addr, a.addr)

proc loadFlPack(path: string): FlPack =
    echo "Loading \"", path, "\"..."

    result.path = path
    result.name = result.path.splitFile.name

    var inStream = newFileStream(result.path, fmRead)
    if not inStream.isNil:
        try:
            # Loop until no more next chunks
            var chunkCount = 0
            while true:
                var chunk: FlPackChunk

                echo &"\n### CHUNK {chunkCount}"
                chunk.header.nextChunk = inStream.readSwappedUint32
                chunk.header.fileAmount = inStream.readSwappedUint32

                echo &"# Next Chunk: {chunk.header.nextChunk:#010x}"
                echo &"# Assets: {chunk.header.fileAmount}"

                # Loop through assets
                for i in 0..<chunk.header.fileAmount:
                    var asset: AssetHeader

                    asset.nameLength = inStream.readSwappedUint32
                    asset.assetName = inStream.readStr(asset.nameLength.int)
                    asset.assetoffset = inStream.readSwappedUint32
                    asset.dataLength = inStream.readSwappedUint32
                    asset.checksum = inStream.readSwappedUint32

                    echo asset.assetName
                    chunk.assets.add(asset)
                    
                result.chunks.add(chunk)

                if chunk.header.nextChunk == 0:
                    break
                chunkCount.inc
                inStream.setPosition(chunk.header.nextChunk.int)

        finally:
            inStream.close


when isMainModule:
    discard loadFlPack(r"Assets_000.pack")